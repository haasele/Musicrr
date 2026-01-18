package com.haasele.musicrr.visualizer

import android.opengl.GLES20
import android.opengl.GLSurfaceView
import android.util.Log
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer
import javax.microedition.khronos.egl.EGLConfig
import javax.microedition.khronos.opengles.GL10

/**
 * OpenGL ES renderer for .milk visualizations
 * This is a simplified implementation that can be extended
 */
class VisualizerRenderer : GLSurfaceView.Renderer {
    companion object {
        private const val TAG = "VisualizerRenderer"
        
        // Vertex shader code
        private const val vertexShaderCode = """
            attribute vec4 vPosition;
            void main() {
                gl_Position = vPosition;
            }
        """
        
        // Fragment shader code (basic)
        private const val fragmentShaderCode = """
            precision mediump float;
            uniform float time;
            uniform vec2 resolution;
            uniform float bass;
            uniform float mid;
            uniform float treble;
            
            void main() {
                vec2 uv = gl_FragCoord.xy / resolution;
                vec3 color = vec3(0.0);
                
                // Simple visualization based on audio data
                float wave = sin(uv.x * 10.0 + time * 2.0) * bass;
                float dist = abs(uv.y - 0.5 - wave * 0.3);
                color = vec3(1.0 - dist * 5.0) * vec3(bass, mid, treble);
                
                gl_FragColor = vec4(color, 1.0);
            }
        """
    }
    
    private var program: Int = 0
    private var timeUniform: Int = 0
    private var resolutionUniform: Int = 0
    private var bassUniform: Int = 0
    private var midUniform: Int = 0
    private var trebleUniform: Int = 0
    
    private var preset: MilkPreset? = null
    private var startTime: Long = 0
    private var fftData: FloatArray? = null
    private var sampleRate: Int = 44100
    
    // Audio data
    private var bassLevel: Float = 0.0f
    private var midLevel: Float = 0.0f
    private var trebleLevel: Float = 0.0f
    
    /**
     * Load a .milk preset
     */
    fun loadPreset(preset: MilkPreset) {
        this.preset = preset
        // In a full implementation, we would compile custom shaders from the preset
        // For now, we use the default shader
    }
    
    /**
     * Update FFT data for visualization
     */
    fun updateFFTData(fftData: FloatArray, sampleRate: Int) {
        this.fftData = fftData
        this.sampleRate = sampleRate
        
        // Calculate frequency bands
        calculateFrequencyBands(fftData, sampleRate)
    }
    
    private fun calculateFrequencyBands(fftData: FloatArray, sampleRate: Int) {
        if (fftData.isEmpty()) return
        
        val nyquist = sampleRate / 2
        val binSize = nyquist.toFloat() / fftData.size
        
        // Bass: 20-250 Hz
        val bassStart = (20 / binSize).toInt().coerceAtLeast(0)
        val bassEnd = (250 / binSize).toInt().coerceAtMost(fftData.size - 1)
        bassLevel = calculateAverage(fftData, bassStart, bassEnd)
        
        // Mid: 250-4000 Hz
        val midStart = (250 / binSize).toInt().coerceAtLeast(0)
        val midEnd = (4000 / binSize).toInt().coerceAtMost(fftData.size - 1)
        midLevel = calculateAverage(fftData, midStart, midEnd)
        
        // Treble: 4000-20000 Hz
        val trebleStart = (4000 / binSize).toInt().coerceAtLeast(0)
        val trebleEnd = (20000 / binSize).toInt().coerceAtMost(fftData.size - 1)
        trebleLevel = calculateAverage(fftData, trebleStart, trebleEnd)
    }
    
    private fun calculateAverage(data: FloatArray, start: Int, end: Int): Float {
        if (start >= end || start < 0 || end > data.size) return 0.0f
        var sum = 0.0f
        for (i in start until end) {
            sum += data[i]
        }
        return sum / (end - start)
    }
    
    override fun onSurfaceCreated(gl: GL10?, config: EGLConfig?) {
        GLES20.glClearColor(0.0f, 0.0f, 0.0f, 1.0f)
        
        // Compile shaders
        val vertexShader = loadShader(GLES20.GL_VERTEX_SHADER, vertexShaderCode)
        val fragmentShader = loadShader(GLES20.GL_FRAGMENT_SHADER, fragmentShaderCode)
        
        // Create program
        program = GLES20.glCreateProgram()
        GLES20.glAttachShader(program, vertexShader)
        GLES20.glAttachShader(program, fragmentShader)
        GLES20.glLinkProgram(program)
        
        // Check linking status
        val linkStatus = IntArray(1)
        GLES20.glGetProgramiv(program, GLES20.GL_LINK_STATUS, linkStatus, 0)
        if (linkStatus[0] == 0) {
            val info = GLES20.glGetProgramInfoLog(program)
            Log.e(TAG, "Error linking program: $info")
            GLES20.glDeleteProgram(program)
            return
        }
        
        // Get uniform locations
        timeUniform = GLES20.glGetUniformLocation(program, "time")
        resolutionUniform = GLES20.glGetUniformLocation(program, "resolution")
        bassUniform = GLES20.glGetUniformLocation(program, "bass")
        midUniform = GLES20.glGetUniformLocation(program, "mid")
        trebleUniform = GLES20.glGetUniformLocation(program, "treble")
        
        startTime = System.currentTimeMillis()
    }
    
    override fun onSurfaceChanged(gl: GL10?, width: Int, height: Int) {
        GLES20.glViewport(0, 0, width, height)
    }
    
    override fun onDrawFrame(gl: GL10?) {
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT)
        
        if (program == 0) return
        
        GLES20.glUseProgram(program)
        
        // Set uniforms
        val currentTime = (System.currentTimeMillis() - startTime) / 1000.0f
        GLES20.glUniform1f(timeUniform, currentTime)
        
        // Get viewport dimensions
        val viewport = IntArray(4)
        GLES20.glGetIntegerv(GLES20.GL_VIEWPORT, viewport, 0)
        GLES20.glUniform2f(resolutionUniform, viewport[2].toFloat(), viewport[3].toFloat())
        
        // Set audio data
        GLES20.glUniform1f(bassUniform, bassLevel)
        GLES20.glUniform1f(midUniform, midLevel)
        GLES20.glUniform1f(trebleUniform, trebleLevel)
        
        // Draw fullscreen quad
        val vertices = floatArrayOf(
            -1.0f, -1.0f, 0.0f,
            1.0f, -1.0f, 0.0f,
            -1.0f, 1.0f, 0.0f,
            1.0f, 1.0f, 0.0f
        )
        
        val vertexBuffer = ByteBuffer.allocateDirect(vertices.size * 4)
            .order(ByteOrder.nativeOrder())
            .asFloatBuffer()
        vertexBuffer.put(vertices)
        vertexBuffer.position(0)
        
        val positionHandle = GLES20.glGetAttribLocation(program, "vPosition")
        GLES20.glEnableVertexAttribArray(positionHandle)
        GLES20.glVertexAttribPointer(positionHandle, 3, GLES20.GL_FLOAT, false, 0, vertexBuffer)
        
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)
        GLES20.glDisableVertexAttribArray(positionHandle)
    }
    
    private fun loadShader(type: Int, shaderCode: String): Int {
        val shader = GLES20.glCreateShader(type)
        GLES20.glShaderSource(shader, shaderCode)
        GLES20.glCompileShader(shader)
        
        val compileStatus = IntArray(1)
        GLES20.glGetShaderiv(shader, GLES20.GL_COMPILE_STATUS, compileStatus, 0)
        if (compileStatus[0] == 0) {
            val info = GLES20.glGetShaderInfoLog(shader)
            Log.e(TAG, "Error compiling shader: $info")
            GLES20.glDeleteShader(shader)
            return 0
        }
        
        return shader
    }
    
    fun release() {
        if (program != 0) {
            GLES20.glDeleteProgram(program)
            program = 0
        }
    }
}
