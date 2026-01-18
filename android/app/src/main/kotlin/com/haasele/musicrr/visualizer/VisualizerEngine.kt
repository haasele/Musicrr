package com.haasele.musicrr.visualizer

import android.content.Context
import android.media.audiofx.Visualizer
import android.util.Log
import java.io.File

/**
 * Visualizer engine that manages .milk preset loading and FFT data
 */
class VisualizerEngine(private val context: Context) {
    companion object {
        private const val TAG = "VisualizerEngine"
    }
    
    private var visualizer: Visualizer? = null
    private var audioSessionId: Int = -1
    private var preset: MilkPreset? = null
    private var presetParser = MilkPresetParser()
    private var onFFTDataCallback: ((FloatArray, Int) -> Unit)? = null
    
    /**
     * Attach to audio session
     */
    fun attachToAudioSession(sessionId: Int) {
        if (visualizer != null) {
            release()
        }
        
        this.audioSessionId = sessionId
        
        try {
            visualizer = Visualizer(sessionId)
            visualizer?.captureSize = Visualizer.getCaptureSizeRange()[1] // Max size
            
            visualizer?.setDataCaptureListener(
                object : Visualizer.OnDataCaptureListener {
                    override fun onWaveFormDataCapture(
                        visualizer: Visualizer,
                        waveform: ByteArray,
                        samplingRate: Int
                    ) {
                        // Not used for now
                    }
                    
                    override fun onFftDataCapture(
                        visualizer: Visualizer,
                        fft: ByteArray,
                        samplingRate: Int
                    ) {
                        // Convert FFT data to float array
                        val fftData = convertFFTToFloatArray(fft)
                        onFFTDataCallback?.invoke(fftData, samplingRate)
                    }
                },
                Visualizer.getMaxCaptureRate() / 2, // ~30 FPS
                false, // Waveform
                true   // FFT
            )
            
            visualizer?.enabled = true
        } catch (e: Exception) {
            Log.e(TAG, "Error attaching visualizer to session $sessionId", e)
        }
    }
    
    /**
     * Load .milk preset from file
     */
    fun loadPreset(presetPath: String): Boolean {
        val file = File(presetPath)
        if (!file.exists()) {
            Log.e(TAG, "Preset file not found: $presetPath")
            return false
        }
        
        val parsedPreset = presetParser.parsePreset(file)
        if (parsedPreset != null) {
            preset = parsedPreset
            Log.d(TAG, "Loaded preset: ${parsedPreset.name}")
            return true
        }
        
        return false
    }
    
    /**
     * Get current preset
     */
    fun getCurrentPreset(): MilkPreset? = preset
    
    /**
     * Set callback for FFT data updates
     */
    fun setOnFFTDataCallback(callback: (FloatArray, Int) -> Unit) {
        this.onFFTDataCallback = callback
    }
    
    /**
     * Convert FFT byte array to float array (magnitude spectrum)
     */
    private fun convertFFTToFloatArray(fft: ByteArray): FloatArray {
        val size = fft.size / 2
        val magnitude = FloatArray(size)
        
        for (i in 0 until size) {
            val real = fft[i * 2].toInt()
            val imag = fft[i * 2 + 1].toInt()
            magnitude[i] = kotlin.math.sqrt((real * real + imag * imag).toDouble()).toFloat()
        }
        
        return magnitude
    }
    
    /**
     * Release visualizer resources
     */
    fun release() {
        visualizer?.enabled = false
        visualizer?.release()
        visualizer = null
        audioSessionId = -1
    }
}
