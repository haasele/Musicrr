package com.haasele.musicrr.dsp

import com.google.android.exoplayer2.audio.AudioProcessor
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.*

/**
 * Crossfade mixer for seamless track transitions
 * Note: This is a simplified implementation. Full crossfade requires
 * dual ExoPlayer instances which is handled at a higher level.
 * This processor handles the mixing part when crossfade is active.
 */
class CrossfadeMixer : AudioProcessor {
    private var enabled: Boolean = false
    private var durationMs: Int = 3000  // 3 seconds default
    private var fadePosition: Long = 0   // Current position in fade (samples)
    private var sampleRate: Int = 44100
    private var channelCount: Int = 2
    
    // Buffer for next track samples (filled externally)
    private var nextTrackBuffer: FloatArray? = null
    private var nextTrackBufferPosition: Int = 0
    
    private var inputAudioFormat: AudioProcessor.AudioFormat? = null
    private var outputAudioFormat: AudioProcessor.AudioFormat? = null
    private var inputBuffer: ByteBuffer? = null
    private var outputBuffer: ByteBuffer? = null
    private var buffer: FloatArray? = null
    
    /**
     * Enable crossfade
     */
    fun enable(durationMs: Int) {
        this.enabled = true
        this.durationMs = durationMs
        this.fadePosition = 0
        this.nextTrackBufferPosition = 0
    }
    
    /**
     * Disable crossfade
     */
    fun disable() {
        this.enabled = false
        this.fadePosition = 0
        this.nextTrackBuffer = null
        this.nextTrackBufferPosition = 0
    }
    
    /**
     * Set next track buffer (called externally when preparing next track)
     */
    fun setNextTrackBuffer(buffer: FloatArray) {
        this.nextTrackBuffer = buffer
        this.nextTrackBufferPosition = 0
    }
    
    /**
     * Check if crossfade is active
     */
    fun isEnabled(): Boolean = enabled
    
    override fun isActive(): Boolean {
        return enabled && nextTrackBuffer != null
    }
    
    override fun configure(inputAudioFormat: AudioProcessor.AudioFormat): AudioProcessor.AudioFormat {
        this.inputAudioFormat = inputAudioFormat
        this.outputAudioFormat = inputAudioFormat
        this.sampleRate = inputAudioFormat.sampleRate
        this.channelCount = inputAudioFormat.channelCount
        
        // Allocate buffers
        val bufferSize = inputAudioFormat.sampleRate * inputAudioFormat.channelCount * 2 // 2 seconds max
        inputBuffer = ByteBuffer.allocateDirect(bufferSize * 4).order(ByteOrder.nativeOrder())
        outputBuffer = ByteBuffer.allocateDirect(bufferSize * 4).order(ByteOrder.nativeOrder())
        buffer = FloatArray(bufferSize)
        
        return outputAudioFormat!!
    }
    
    override fun queueInput(inputBuffer: ByteBuffer) {
        val input = this.inputBuffer ?: return
        val remaining = inputBuffer.remaining()
        
        if (input.remaining() < remaining) {
            return
        }
        
        input.put(inputBuffer)
    }
    
    override fun queueEndOfStream() {
        // No-op
    }
    
    override fun getOutput(): ByteBuffer {
        if (!enabled) {
            // Pass through without modification
            val input = inputBuffer ?: return ByteBuffer.allocateDirect(0)
            if (!input.hasRemaining()) {
                return ByteBuffer.allocateDirect(0)
            }
            
            val output = outputBuffer ?: return ByteBuffer.allocateDirect(0)
            output.clear()
            output.put(input)
            input.clear()
            output.flip()
            return output
        }
        
        val input = inputBuffer ?: return ByteBuffer.allocateDirect(0)
        val output = outputBuffer ?: return ByteBuffer.allocateDirect(0)
        val samples = buffer ?: return ByteBuffer.allocateDirect(0)
        val nextSamples = nextTrackBuffer
        
        if (!input.hasRemaining()) {
            return ByteBuffer.allocateDirect(0)
        }
        
        val sampleCount = input.remaining() / (2 * channelCount) // 16-bit samples
        
        if (sampleCount > samples.size) {
            return ByteBuffer.allocateDirect(0)
        }
        
        // Convert ByteBuffer to float array
        input.order(ByteOrder.LITTLE_ENDIAN)
        for (i in 0 until sampleCount * channelCount) {
            samples[i] = input.short.toFloat() / 32768.0f
        }
        
        // Calculate fade curves
        val fadeDurationSamples = (durationMs * sampleRate / 1000).toLong()
        val fadeOut = calculateFadeOut(fadePosition, fadeDurationSamples)
        val fadeIn = calculateFadeIn(fadePosition, fadeDurationSamples)
        
        // Mix samples if next track buffer is available
        if (nextSamples != null && nextTrackBufferPosition < nextSamples.size) {
            val availableNextSamples = minOf(
                sampleCount * channelCount,
                nextSamples.size - nextTrackBufferPosition
            )
            
            for (i in 0 until availableNextSamples) {
                val currentSample = samples[i]
                val nextSample = nextSamples[nextTrackBufferPosition + i]
                samples[i] = currentSample * fadeOut + nextSample * fadeIn
            }
            
            nextTrackBufferPosition += availableNextSamples
        } else {
            // Only fade out current track
            for (i in 0 until sampleCount * channelCount) {
                samples[i] *= fadeOut
            }
        }
        
        fadePosition += sampleCount
        
        // Check if fade is complete
        if (fadePosition >= fadeDurationSamples) {
            disable()
        }
        
        // Convert back to ByteBuffer
        output.clear()
        output.order(ByteOrder.LITTLE_ENDIAN)
        for (i in 0 until sampleCount * channelCount) {
            val sample = (samples[i].coerceIn(-1.0f, 1.0f) * 32767.0f).toInt().toShort()
            output.putShort(sample)
        }
        
        input.clear()
        output.flip()
        
        return output
    }
    
    private fun calculateFadeOut(position: Long, duration: Long): Float {
        if (duration == 0L) return 1.0f
        val progress = (position.toFloat() / duration.toFloat()).coerceIn(0.0f, 1.0f)
        // Linear fade: 1.0 → 0.0
        return 1.0f - progress
        // Alternative: Exponential fade (smoother)
        // return exp(-progress * 5.0f)
    }
    
    private fun calculateFadeIn(position: Long, duration: Long): Float {
        if (duration == 0L) return 0.0f
        val progress = (position.toFloat() / duration.toFloat()).coerceIn(0.0f, 1.0f)
        // Linear fade: 0.0 → 1.0
        return progress
        // Alternative: Exponential fade
        // return 1.0f - exp(-progress * 5.0f)
    }
    
    override fun isEnded(): Boolean = false
    
    override fun flush() {
        inputBuffer?.clear()
        outputBuffer?.clear()
        fadePosition = 0
        nextTrackBufferPosition = 0
    }
    
    override fun reset() {
        inputBuffer?.clear()
        outputBuffer?.clear()
        fadePosition = 0
        nextTrackBufferPosition = 0
        nextTrackBuffer = null
        enabled = false
        inputAudioFormat = null
        outputAudioFormat = null
    }
}
