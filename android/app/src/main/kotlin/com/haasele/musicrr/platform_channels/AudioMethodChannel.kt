package com.haasele.musicrr.platform_channels

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class AudioMethodChannel(
    private val flutterEngine: FlutterEngine,
    private val audioEngine: AudioEngineInterface
) {
    private val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.haasele.musicrr/audio")
    private val mainHandler = Handler(Looper.getMainLooper())

    fun setup() {
        channel.setMethodCallHandler { call, result ->
            mainHandler.post {
                handleMethodCall(call, result)
            }
        }
    }

    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "play" -> {
                val uri = call.argument<String>("uri")
                if (uri != null) {
                    audioEngine.play(uri)
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENT", "URI is required", null)
                }
            }
            "playQueue" -> {
                val uris = call.argument<List<String>>("uris")
                val startIndex = call.argument<Int>("startIndex") ?: 0
                if (uris != null) {
                    audioEngine.playQueue(uris, startIndex)
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENT", "URIs are required", null)
                }
            }
            "pause" -> {
                audioEngine.pause()
                result.success(null)
            }
            "resume" -> {
                audioEngine.resume()
                result.success(null)
            }
            "seek" -> {
                val positionMs = call.argument<Int>("positionMs") ?: 0
                audioEngine.seek(positionMs)
                result.success(null)
            }
            "setVolume" -> {
                val volume = call.argument<Double>("volume")?.toFloat() ?: 1.0f
                audioEngine.setVolume(volume)
                result.success(null)
            }
            "setEQ" -> {
                val bands = call.argument<List<Map<String, Any>>>("bands")
                if (bands != null) {
                    audioEngine.setEQ(bands)
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENT", "Bands are required", null)
                }
            }
            "setReplayGain" -> {
                val gainDb = call.argument<Double>("gainDb")?.toFloat() ?: 0.0f
                audioEngine.setReplayGain(gainDb)
                result.success(null)
            }
            "enableCrossfade" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                val durationMs = call.argument<Int>("durationMs") ?: 3000
                audioEngine.enableCrossfade(enabled, durationMs)
                result.success(null)
            }
            "setSampleRate" -> {
                val sampleRate = call.argument<Int>("sampleRate") ?: 48000
                audioEngine.setSampleRate(sampleRate)
                result.success(null)
            }
            "loadVisualizerPreset" -> {
                val presetPath = call.argument<String>("presetPath")
                if (presetPath != null) {
                    audioEngine.loadVisualizerPreset(presetPath)
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENT", "Preset path is required", null)
                }
            }
            "setVisualizerEnabled" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                audioEngine.setVisualizerEnabled(enabled)
                result.success(null)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    interface AudioEngineInterface {
        fun play(uri: String)
        fun playQueue(uris: List<String>, startIndex: Int)
        fun pause()
        fun resume()
        fun seek(positionMs: Int)
        fun setVolume(volume: Float)
        fun setEQ(bands: List<Map<String, Any>>)
        fun setReplayGain(gainDb: Float)
        fun enableCrossfade(enabled: Boolean, durationMs: Int)
        fun setSampleRate(sampleRate: Int)
        fun loadVisualizerPreset(presetPath: String)
        fun setVisualizerEnabled(enabled: Boolean)
    }
}
