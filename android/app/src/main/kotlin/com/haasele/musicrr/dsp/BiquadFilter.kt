package com.haasele.musicrr.dsp

import kotlin.math.*

/**
 * Second-order IIR filter (biquad) for parametric EQ
 * Supports: Low-pass, High-pass, Band-pass, Notch, Peak, Shelf
 */
class BiquadFilter {
    private var b0: Float = 1.0f
    private var b1: Float = 0.0f
    private var b2: Float = 0.0f
    private var a1: Float = 0.0f
    private var a2: Float = 0.0f
    
    // State variables (for filter history)
    private var x1: Float = 0.0f
    private var x2: Float = 0.0f
    private var y1: Float = 0.0f
    private var y2: Float = 0.0f
    
    private var sampleRate: Float = 44100f
    private var configured: Boolean = false
    
    /**
     * Configure as a peak filter (most common for parametric EQ)
     */
    fun configurePeak(frequency: Float, gain: Float, q: Float, sampleRate: Float) {
        this.sampleRate = sampleRate
        val w = 2.0 * PI * frequency / sampleRate
        val cosw = cos(w).toFloat()
        val sinw = sin(w).toFloat()
        val alpha = sinw / (2.0 * q).toFloat()
        val A = 10.0.pow(gain / 40.0).toFloat()
        val S = 1.0f
        val beta = sqrt(A) / q
        
        val b0 = 1.0f + alpha * A
        val b1 = -2.0f * cosw
        val b2 = 1.0f - alpha * A
        val a0 = 1.0f + alpha / A
        val a1 = -2.0f * cosw
        val a2 = 1.0f - alpha / A
        
        this.b0 = b0 / a0
        this.b1 = b1 / a0
        this.b2 = b2 / a0
        this.a1 = a1 / a0
        this.a2 = a2 / a0
        
        configured = true
        reset()
    }
    
    /**
     * Configure as a low shelf filter
     */
    fun configureLowShelf(frequency: Float, gain: Float, q: Float, sampleRate: Float) {
        this.sampleRate = sampleRate
        val w = 2.0 * PI * frequency / sampleRate
        val cosw = cos(w).toFloat()
        val sinw = sin(w).toFloat()
        val A = 10.0.pow(gain / 40.0).toFloat()
        val S = 1.0f
        val alpha = sinw / 2.0f * sqrt((A + 1.0 / A) * (1.0 / S - 1.0) + 2.0).toFloat()
        val beta = sqrt(A) / q
        
        val b0 = A * ((A + 1.0f) - (A - 1.0f) * cosw + beta * sinw)
        val b1 = 2.0f * A * ((A - 1.0f) - (A + 1.0f) * cosw)
        val b2 = A * ((A + 1.0f) - (A - 1.0f) * cosw - beta * sinw)
        val a0 = (A + 1.0f) + (A - 1.0f) * cosw + beta * sinw
        val a1 = -2.0f * ((A - 1.0f) + (A + 1.0f) * cosw)
        val a2 = (A + 1.0f) + (A - 1.0f) * cosw - beta * sinw
        
        this.b0 = b0 / a0
        this.b1 = b1 / a0
        this.b2 = b2 / a0
        this.a1 = a1 / a0
        this.a2 = a2 / a0
        
        configured = true
        reset()
    }
    
    /**
     * Configure as a high shelf filter
     */
    fun configureHighShelf(frequency: Float, gain: Float, q: Float, sampleRate: Float) {
        this.sampleRate = sampleRate
        val w = 2.0 * PI * frequency / sampleRate
        val cosw = cos(w).toFloat()
        val sinw = sin(w).toFloat()
        val A = 10.0.pow(gain / 40.0).toFloat()
        val S = 1.0f
        val alpha = sinw / 2.0f * sqrt((A + 1.0 / A) * (1.0 / S - 1.0) + 2.0).toFloat()
        val beta = sqrt(A) / q
        
        val b0 = A * ((A + 1.0f) + (A - 1.0f) * cosw + beta * sinw)
        val b1 = -2.0f * A * ((A - 1.0f) + (A + 1.0f) * cosw)
        val b2 = A * ((A + 1.0f) + (A - 1.0f) * cosw - beta * sinw)
        val a0 = (A + 1.0f) - (A - 1.0f) * cosw + beta * sinw
        val a1 = 2.0f * ((A - 1.0f) - (A + 1.0f) * cosw)
        val a2 = (A + 1.0f) - (A - 1.0f) * cosw - beta * sinw
        
        this.b0 = b0 / a0
        this.b1 = b1 / a0
        this.b2 = b2 / a0
        this.a1 = a1 / a0
        this.a2 = a2 / a0
        
        configured = true
        reset()
    }
    
    /**
     * Process audio samples (in-place)
     */
    fun process(samples: FloatArray) {
        if (!configured) return
        
        for (i in samples.indices) {
            val input = samples[i]
            val output = b0 * input + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
            
            // Update state
            x2 = x1
            x1 = input
            y2 = y1
            y1 = output
            
            samples[i] = output
        }
    }
    
    /**
     * Process interleaved stereo samples
     */
    fun processInterleaved(samples: FloatArray, channelCount: Int) {
        if (!configured || channelCount < 1) return
        
        for (i in 0 until samples.size step channelCount) {
            for (ch in 0 until channelCount) {
                val idx = i + ch
                if (idx >= samples.size) break
                
                val input = samples[idx]
                val output = b0 * input + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
                
                // Update state
                x2 = x1
                x1 = input
                y2 = y1
                y1 = output
                
                samples[idx] = output
            }
        }
    }
    
    /**
     * Reset filter state (clear history)
     */
    fun reset() {
        x1 = 0.0f
        x2 = 0.0f
        y1 = 0.0f
        y2 = 0.0f
    }
    
    /**
     * Check if filter is configured
     */
    fun isConfigured(): Boolean = configured
}
