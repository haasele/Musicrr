package com.haasele.musicrr.dsp

import com.google.android.exoplayer2.audio.AudioProcessor
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.*

/**
 * Parametric EQ processor using biquad filters
 * Supports multiple bands with configurable frequency, gain, and Q
 */
data class EQBand(
    val frequency: Float,  // Hz (20 - 20000)
    val gain: Float,       // dB (-12 to +12)
    val q: Float           // Quality factor (0.1 - 10.0)
)

class ParametricEQProcessor : AudioProcessor {
    private var bands: List<EQBand> = emptyList()
    private var preamp: Float = 0.0f
    private var limiterEnabled: Boolean = true
    private val limiterThreshold: Float = 0.95f
    
    // Biquad filters for each band
    private val filters: MutableList<BiquadFilter> = mutableListOf()
    
    private var inputAudioFormat: AudioProcessor.AudioFormat? = null
    private var outputAudioFormat: AudioProcessor.AudioFormat? = null
    private var inputBuffer: ByteBuffer? = null
    private var outputBuffer: ByteBuffer? = null
    private var buffer: FloatArray? = null
    
    /**
     * Set EQ bands
     */
    fun setBands(bands: List<EQBand>) {
        this.bands = bands
        updateFilters()
    }
    
    /**
     * Set preamp gain in dB
     */
    fun setPreamp(preampDb: Float) {
        this.preamp = preampDb
    }
    
    /**
     * Enable/disable limiter
     */
    fun setLimiterEnabled(enabled: Boolean) {
        this.limiterEnabled = enabled
    }
    
    private fun updateFilters() {
        filters.clear()
        val sampleRate = inputAudioFormat?.sampleRate?.toFloat() ?: 44100f
        
        bands.forEach { band ->
            val filter = BiquadFilter()
            
            // Determine filter type based on frequency
            when {
                band.frequency < 100f -> {
                    // Low shelf for very low frequencies
                    filter.configureLowShelf(band.frequency, band.gain, band.q, sampleRate)
                }
                band.frequency > 10000f -> {
                    // High shelf for very high frequencies
                    filter.configureHighShelf(band.frequency, band.gain, band.q, sampleRate)
                }
                else -> {
                    // Peak filter for mid frequencies
                    filter.configurePeak(band.frequency, band.gain, band.q, sampleRate)
                }
            }
            
            filters.add(filter)
        }
    }
    
    override fun isActive(): Boolean {
        return bands.isNotEmpty() || preamp != 0.0f
    }
    
    override fun configure(inputAudioFormat: AudioProcessor.AudioFormat): AudioProcessor.AudioFormat {
        this.inputAudioFormat = inputAudioFormat
        this.outputAudioFormat = inputAudioFormat
        
        // Allocate buffers
        val bufferSize = inputAudioFormat.sampleRate * inputAudioFormat.channelCount * 2 // 2 seconds max
        inputBuffer = ByteBuffer.allocateDirect(bufferSize * 4).order(ByteOrder.nativeOrder())
        outputBuffer = ByteBuffer.allocateDirect(bufferSize * 4).order(ByteOrder.nativeOrder())
        buffer = FloatArray(bufferSize)
        
        updateFilters()
        
        return outputAudioFormat!!
    }
    
    override fun queueInput(inputBuffer: ByteBuffer) {
        val input = this.inputBuffer ?: return
        val remaining = inputBuffer.remaining()
        
        if (input.remaining() < remaining) {
            // Buffer overflow - should not happen in normal operation
            return
        }
        
        input.put(inputBuffer)
    }
    
    override fun queueEndOfStream() {
        // No-op
    }
    
    override fun getOutput(): ByteBuffer {
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
        
        // Convert ByteBuffer to float array
        input.order(ByteOrder.LITTLE_ENDIAN)
        for (i in 0 until sampleCount * channelCount) {
            samples[i] = input.short.toFloat() / 32768.0f
        }
        
        // Apply EQ bands
        filters.forEach { filter ->
            if (channelCount == 1) {
                filter.process(samples.sliceArray(0 until sampleCount))
            } else {
                filter.processInterleaved(samples, channelCount)
            }
        }
        
        // Apply preamp
        val preampGain = 10.0.pow(preamp / 20.0).toFloat()
        for (i in 0 until sampleCount * channelCount) {
            samples[i] *= preampGain
        }
        
        // Apply limiter (prevent clipping)
        if (limiterEnabled) {
            limitSamples(samples, sampleCount * channelCount)
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
    
    private fun limitSamples(samples: FloatArray, count: Int) {
        var maxSample = 0.0f
        
        // First pass: find maximum
        for (i in 0 until count) {
            maxSample = maxOf(maxSample, abs(samples[i]))
        }
        
        // Second pass: apply limiting if needed
        if (maxSample > limiterThreshold) {
            val limitingGain = limiterThreshold / maxSample
            for (i in 0 until count) {
                samples[i] = (samples[i] * limitingGain).coerceIn(-1.0f, 1.0f)
            }
        } else {
            // Clamp to prevent clipping
            for (i in 0 until count) {
                samples[i] = samples[i].coerceIn(-1.0f, 1.0f)
            }
        }
    }
    
    override fun isEnded(): Boolean = false
    
    override fun flush() {
        inputBuffer?.clear()
        outputBuffer?.clear()
        filters.forEach { it.reset() }
    }
    
    override fun reset() {
        inputBuffer?.clear()
        outputBuffer?.clear()
        filters.forEach { it.reset() }
        inputAudioFormat = null
        outputAudioFormat = null
    }
}
