package com.haasele.musicrr.webserver

import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.util.concurrent.CompletableFuture
import java.util.concurrent.TimeUnit

/**
 * Bridge to access audio engine via platform channels from web server thread
 */
class AudioEngineBridge(
    private val methodChannel: MethodChannel,
    private val handler: Handler = Handler(Looper.getMainLooper())
) {
    
    companion object {
        private const val TAG = "AudioEngineBridge"
        private const val CHANNEL_NAME = "com.haasele.musicrr/audio"
        private const val TIMEOUT_SECONDS = 5L
    }
    
    /**
     * Call platform channel method synchronously from background thread
     */
    private fun <T> callMethod(method: String, arguments: Any? = null): CompletableFuture<T> {
        val future = CompletableFuture<T>()
        
        handler.post {
            methodChannel.invokeMethod(method, arguments, object : MethodChannel.Result {
                override fun success(result: Any?) {
                    @Suppress("UNCHECKED_CAST")
                    future.complete(result as? T)
                }
                
                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                    Log.e(TAG, "Method call error: $method - $errorCode: $errorMessage")
                    future.completeExceptionally(
                        Exception("$errorCode: $errorMessage")
                    )
                }
                
                override fun notImplemented() {
                    Log.e(TAG, "Method not implemented: $method")
                    future.completeExceptionally(
                        Exception("Method not implemented: $method")
                    )
                }
            })
        }
        
        return future
    }
    
    /**
     * Get current playback status
     */
    fun getStatus(): Map<String, Any?> {
        return try {
            val result = callMethod<Map<*, *>>("getStatus")
                .get(TIMEOUT_SECONDS, TimeUnit.SECONDS)
            @Suppress("UNCHECKED_CAST")
            result as? Map<String, Any?> ?: emptyMap()
        } catch (e: Exception) {
            Log.e(TAG, "Error getting status", e)
            emptyMap()
        }
    }
    
    /**
     * Play track
     */
    fun play(trackId: String? = null, position: Int = 0): Boolean {
        return try {
            val args = mapOf(
                "trackId" to trackId,
                "position" to position
            )
            val result = callMethod<Boolean>("play", args)
                .get(TIMEOUT_SECONDS, TimeUnit.SECONDS)
            result ?: false
        } catch (e: Exception) {
            Log.e(TAG, "Error playing track", e)
            false
        }
    }
    
    /**
     * Pause playback
     */
    fun pause(): Boolean {
        return try {
            val result = callMethod<Boolean>("pause")
                .get(TIMEOUT_SECONDS, TimeUnit.SECONDS)
            result ?: false
        } catch (e: Exception) {
            Log.e(TAG, "Error pausing", e)
            false
        }
    }
    
    /**
     * Resume playback
     */
    fun resume(): Boolean {
        return try {
            val result = callMethod<Boolean>("resume")
                .get(TIMEOUT_SECONDS, TimeUnit.SECONDS)
            result ?: false
        } catch (e: Exception) {
            Log.e(TAG, "Error resuming", e)
            false
        }
    }
    
    /**
     * Stop playback
     */
    fun stop(): Boolean {
        return try {
            val result = callMethod<Boolean>("stop")
                .get(TIMEOUT_SECONDS, TimeUnit.SECONDS)
            result ?: false
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping", e)
            false
        }
    }
    
    /**
     * Seek to position
     */
    fun seek(positionMs: Int): Boolean {
        return try {
            val result = callMethod<Boolean>("seek", positionMs)
                .get(TIMEOUT_SECONDS, TimeUnit.SECONDS)
            result ?: false
        } catch (e: Exception) {
            Log.e(TAG, "Error seeking", e)
            false
        }
    }
    
    /**
     * Get queue
     */
    fun getQueue(): List<Map<String, Any?>> {
        return try {
            val result = callMethod<List<*>>("getQueue")
                .get(TIMEOUT_SECONDS, TimeUnit.SECONDS)
            @Suppress("UNCHECKED_CAST")
            (result as? List<Map<*, *>>)?.map { 
                @Suppress("UNCHECKED_CAST")
                it as? Map<String, Any?> ?: emptyMap()
            } ?: emptyList()
        } catch (e: Exception) {
            Log.e(TAG, "Error getting queue", e)
            emptyList()
        }
    }
    
    /**
     * Set volume
     */
    fun setVolume(volume: Double): Boolean {
        return try {
            val result = callMethod<Boolean>("setVolume", volume)
                .get(TIMEOUT_SECONDS, TimeUnit.SECONDS)
            result ?: false
        } catch (e: Exception) {
            Log.e(TAG, "Error setting volume", e)
            false
        }
    }
}
