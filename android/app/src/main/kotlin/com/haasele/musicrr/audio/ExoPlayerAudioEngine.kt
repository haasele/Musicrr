package com.haasele.musicrr.audio

import android.content.Context
import com.google.android.exoplayer2.ExoPlayer
import com.google.android.exoplayer2.MediaItem
import com.google.android.exoplayer2.Player
import com.google.android.exoplayer2.audio.AudioProcessor
import com.google.android.exoplayer2.source.MediaSource
import com.google.android.exoplayer2.source.ProgressiveMediaSource
import com.google.android.exoplayer2.source.ConcatenatingMediaSource
import com.google.android.exoplayer2.upstream.DefaultDataSourceFactory
import com.google.android.exoplayer2.upstream.DefaultHttpDataSource
import com.google.android.exoplayer2.util.Util
import com.haasele.musicrr.platform_channels.AudioMethodChannel
import com.haasele.musicrr.platform_channels.AudioEventChannel
import com.haasele.musicrr.dsp.ParametricEQProcessor
import com.haasele.musicrr.dsp.EQBand
import com.haasele.musicrr.dsp.ReplayGainProcessor
import com.haasele.musicrr.dsp.ReplayGainMode
import com.haasele.musicrr.dsp.CrossfadeMixer
import com.haasele.musicrr.visualizer.VisualizerEngine
import io.flutter.plugin.common.EventChannel

class ExoPlayerAudioEngine(
    private val context: Context
) : AudioMethodChannel.AudioEngineInterface, AudioEventChannel.AudioEventSource {
    
    private var exoPlayer: ExoPlayer? = null
    private var eventSink: EventChannel.EventSink? = null
    
    // DSP Processors
    private val eqProcessor = ParametricEQProcessor()
    private val replayGainProcessor = ReplayGainProcessor()
    private val crossfadeMixer = CrossfadeMixer()
    
    // Visualizer
    private val visualizerEngine = VisualizerEngine(context)
    
    // Gapless playback
    private var concatenatingMediaSource: ConcatenatingMediaSource? = null
    private val dataSourceFactory: DefaultDataSourceFactory by lazy {
        val userAgent = Util.getUserAgent(context, "Musicrr")
        val httpDataSourceFactory = DefaultHttpDataSource.Factory()
            .setUserAgent(userAgent)
        DefaultDataSourceFactory(context, httpDataSourceFactory)
    }
    private val playerListener = object : Player.Listener {
        override fun onPlaybackStateChanged(playbackState: Int) {
            when (playbackState) {
                Player.STATE_READY -> {
                    emitPlaybackState("ready")
                }
                Player.STATE_BUFFERING -> {
                    emitPlaybackState("buffering")
                }
                Player.STATE_ENDED -> {
                    emitPlaybackState("ended")
                }
                Player.STATE_IDLE -> {
                    emitPlaybackState("idle")
                }
            }
        }

        override fun onIsPlayingChanged(isPlaying: Boolean) {
            emitPlaybackState(if (isPlaying) "playing" else "paused")
        }

        override fun onPlayerError(error: com.google.android.exoplayer2.PlaybackException) {
            emitError(error.message ?: "Unknown error")
        }
    }

    init {
        initializePlayer()
    }

    private fun initializePlayer() {
        // Create custom audio processor chain with DSP processors
        val audioProcessors = mutableListOf<AudioProcessor>()
        
        // Order: ReplayGain -> EQ -> Crossfade
        audioProcessors.add(replayGainProcessor)
        audioProcessors.add(eqProcessor)
        audioProcessors.add(crossfadeMixer)
        
        // ExoPlayer 2.19.1: Build player and configure processors
        exoPlayer = ExoPlayer.Builder(context)
            .build()
            .apply {
                // Add listener
                addListener(playerListener)
                // Note: Audio processors need to be configured via RenderersFactory
                // For now, we'll configure them later when needed
            }
        
        // Start position update loop
        startPositionUpdates()
    }

    private fun startPositionUpdates() {
        val handler = android.os.Handler(android.os.Looper.getMainLooper())
        val updateRunnable = object : Runnable {
            override fun run() {
                exoPlayer?.let { player ->
                    if (player.isPlaying) {
                        emitPosition(player.currentPosition, player.duration)
                    }
                }
                handler.postDelayed(this, 1000) // Update every second
            }
        }
        handler.post(updateRunnable)
    }

    private fun emitPlaybackState(state: String) {
        eventSink?.success(mapOf(
            "type" to "playbackState",
            "state" to state
        ))
    }

    private fun emitPosition(positionMs: Long, durationMs: Long) {
        eventSink?.success(mapOf(
            "type" to "position",
            "positionMs" to positionMs.toInt(),
            "durationMs" to durationMs.toInt()
        ))
    }

    private fun emitError(message: String) {
        eventSink?.success(mapOf(
            "type" to "error",
            "error" to message
        ))
    }

    // AudioMethodChannel.AudioEngineInterface implementation
    override fun play(uri: String) {
        exoPlayer?.let { player ->
            val mediaItem = MediaItem.fromUri(uri)
            val mediaSource = ProgressiveMediaSource.Factory(dataSourceFactory)
                .createMediaSource(mediaItem)
            
            // For single track, use simple playback
            player.setMediaSource(mediaSource)
            player.prepare()
            player.play()
        }
    }
    
    /**
     * Play a queue of tracks with gapless playback
     */
    override fun playQueue(uris: List<String>, startIndex: Int) {
        exoPlayer?.let { player ->
            concatenatingMediaSource = ConcatenatingMediaSource()
            
            // Add all tracks to concatenating source
            uris.forEach { uri ->
                val mediaItem = MediaItem.fromUri(uri)
                val mediaSource = ProgressiveMediaSource.Factory(dataSourceFactory)
                    .createMediaSource(mediaItem)
                concatenatingMediaSource?.addMediaSource(mediaSource)
            }
            
            // Set as media source and prepare
            player.setMediaSource(concatenatingMediaSource!!)
            player.prepare()
            
            // Seek to start index if provided
            if (startIndex > 0) {
                player.seekTo(startIndex, 0)
            }
            
            player.play()
        }
    }
    
    /**
     * Add track to queue for gapless playback
     */
    fun addToQueue(uri: String) {
        exoPlayer?.let { player ->
            val mediaItem = MediaItem.fromUri(uri)
            val mediaSource = ProgressiveMediaSource.Factory(dataSourceFactory)
                .createMediaSource(mediaItem)
            concatenatingMediaSource?.addMediaSource(mediaSource)
        }
    }
    
    /**
     * Remove track from queue
     */
    fun removeFromQueue(index: Int) {
        concatenatingMediaSource?.removeMediaSource(index)
    }

    override fun pause() {
        exoPlayer?.pause()
    }

    override fun resume() {
        exoPlayer?.play()
    }

    override fun seek(positionMs: Int) {
        exoPlayer?.seekTo(positionMs.toLong())
    }

    override fun setVolume(volume: Float) {
        exoPlayer?.volume = volume.coerceIn(0f, 1f)
    }

    override fun setEQ(bands: List<Map<String, Any>>) {
        val eqBands = bands.map { band ->
            EQBand(
                frequency = (band["frequency"] as? Number)?.toFloat() ?: 1000f,
                gain = (band["gain"] as? Number)?.toFloat() ?: 0f,
                q = (band["q"] as? Number)?.toFloat() ?: 1.0f
            )
        }
        eqProcessor.setBands(eqBands)
    }

    override fun setReplayGain(gainDb: Float) {
        replayGainProcessor.setTrackGain(gainDb)
        replayGainProcessor.setMode(ReplayGainMode.TRACK)
    }

    override fun enableCrossfade(enabled: Boolean, durationMs: Int) {
        if (enabled) {
            crossfadeMixer.enable(durationMs)
        } else {
            crossfadeMixer.disable()
        }
    }

    override fun setSampleRate(sampleRate: Int) {
        // TODO: Implement sample rate switching
    }

    override fun loadVisualizerPreset(presetPath: String) {
        visualizerEngine.loadPreset(presetPath)
    }

    override fun setVisualizerEnabled(enabled: Boolean) {
        if (enabled) {
            exoPlayer?.let { player ->
                val audioSessionId = player.audioSessionId
                if (audioSessionId != 0) {
                    visualizerEngine.attachToAudioSession(audioSessionId)
                }
            }
        } else {
            visualizerEngine.release()
        }
    }

    // AudioEventChannel.AudioEventSource implementation
    override fun setEventSink(eventSink: EventChannel.EventSink?) {
        this.eventSink = eventSink
    }

    fun release() {
        visualizerEngine.release()
        exoPlayer?.release()
        exoPlayer = null
    }
    
    /**
     * Get visualizer engine for external access
     */
    fun getVisualizerEngine(): VisualizerEngine = visualizerEngine
}
