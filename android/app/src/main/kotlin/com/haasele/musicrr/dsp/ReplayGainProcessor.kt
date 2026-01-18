package com.haasele.musicrr.dsp

import com.google.android.exoplayer2.audio.AudioProcessor
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.*

/**
 * ReplayGain processor for volume normalization
 * Supports track-level and album-level gain
 */
enum class ReplayGainMode {
    TRACK,      // Use track gain
    ALBUM,      // Use album gain
    DISABLED    // No gain adjustment
}

class ReplayGainProcessor : AudioProcessor {
    private var trackGain: Float = 0.0f  // dB
    private var albumGain: Float = 0.0f  // dB
    private var mode: ReplayGainMode = ReplayGainMode.DISABLED
    private var limiterEnabled: Boolean = true
    private val limiterThreshold: Float = 0.95f
    
    private var inputAudioFormat: AudioProcessor.AudioFormat? = null
    private var outputAudioFormat: AudioProcessor.AudioFormat? = null
    private var inputBuffer: ByteBuffer? = null
    private var outputBuffer: ByteBuffer? = null
    private var buffer: FloatArray? = null
    
    /**
     * Set track gain in dB
     */
    fun setTrackGain(gainDb: Float) {
        this.trackGain = gainDb
    }
    
    /**
     * Set album gain in dB
     */
    fun setAlbumGain(gainDb: Float) {
        this.albumGain = gainDb
    }
    
    /**
     * Set ReplayGain mode
     */
    fun setMode(mode: ReplayGainMode) {
        this.mode = mode
    }
    
    /**
     * Enable/disable limiter
     */
    fun setLimiterEnabled(enabled: Boolean) {
        this.limiterEnabled = enabled
    }
    
    override fun isActive(): Boolean {
        return mode != ReplayGainMode.DISABLED && (trackGain != 0.0f || albumGain != 0.0f)
    }
    
    override fun configure(inputAudioFormat: AudioProcessor.AudioFormat): AudioProcessor.AudioFormat {
        this.inputAudioFormat = inputAudioFormat
        this.outputAudioFormat = inputAudioFormat
        
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
        if (mode == ReplayGainMode.DISABLED) {
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
        
        if (!input.hasRemaining()) {
            return ByteBuffer.allocateDirect(0)
        }
        
        val inputAudioFormat = this.inputAudioFormat ?: return ByteBuffer.allocateDirect(0)
        val channelCount = inputAudioFormat.channelCount
        val sampleCount = input.remaining() / (2 * channelCount) // 16-bit samples
        
        if (sampleCount > samples.size) {
            return ByteBuffer.allocateDirect(0)
        }
        
        // Get gain based on mode
        val gainDb = when (mode) {
            ReplayGainMode.TRACK -> trackGain
            ReplayGainMode.ALBUM -> albumGain
            ReplayGainMode.DISABLED -> 0.0f
        }
        
        if (gainDb == 0.0f) {
            // No gain adjustment needed
            output.clear()
            output.put(input)
            input.clear()
            output.flip()
            return output
        }
        
        // Convert to linear gain
        val linearGain = 10.0.pow(gainDb / 20.0).toFloat()
        
        // Convert ByteBuffer to float array
        input.order(ByteOrder.LITTLE_ENDIAN)
        for (i in 0 until sampleCount * channelCount) {
            samples[i] = input.short.toFloat() / 32768.0f
        }
        
        // Apply gain with limiting
        if (limiterEnabled) {
            applyReplayGainWithLimiting(samples, sampleCount * channelCount, linearGain)
        } else {
            // Simple gain application
            for (i in 0 until sampleCount * channelCount) {
                samples[i] = (samples[i] * linearGain).coerceIn(-1.0f, 1.0f)
            }
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
    
    private fun applyReplayGainWithLimiting(
        samples: FloatArray,
        count: Int,
        linearGain: Float
    ) {
        var maxSample = 0.0f
        
        // First pass: find maximum after gain
        for (i in 0 until count) {
            val amplified = samples[i] * linearGain
            maxSample = maxOf(maxSample, abs(amplified))
        }
        
        // Second pass: apply gain with limiting if needed
        if (maxSample > limiterThreshold) {
            val limitingGain = limiterThreshold / maxSample
            for (i in 0 until count) {
                samples[i] = (samples[i] * linearGain * limitingGain).coerceIn(-1.0f, 1.0f)
            }
        } else {
            // Apply gain and clamp
            for (i in 0 until count) {
                samples[i] = (samples[i] * linearGain).coerceIn(-1.0f, 1.0f)
            }
        }
    }
    
    override fun isEnded(): Boolean = false
    
    override fun flush() {
        inputBuffer?.clear()
        outputBuffer?.clear()
    }
    
    override fun reset() {
        inputBuffer?.clear()
        outputBuffer?.clear()
        inputAudioFormat = null
        outputAudioFormat = null
    }
}
