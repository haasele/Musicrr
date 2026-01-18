package com.haasele.musicrr.platform_channels

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.haasele.musicrr.webserver.*
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class RemoteControlMethodChannel(
    private val context: Context,
    flutterEngine: FlutterEngine
) : MethodCallHandler {
    
    companion object {
        private const val TAG = "RemoteControlMethodChannel"
        private const val CHANNEL_NAME = "com.haasele.musicrr/remote_control"
    }
    
    private val flutterEngine: FlutterEngine = flutterEngine
    private var webServer: MusicrrWebServer? = null
    private var tokenManager: TokenManager? = null
    private var apiRouter: ApiRouter? = null
    private var webSocketHandler: WebSocketHandler? = null
    private var audioEngineBridge: AudioEngineBridge? = null
    
    init {
        val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        methodChannel.setMethodCallHandler(this)
    }
    
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "startServer" -> {
                val port = call.argument<Int>("port") ?: 8080
                startServer(port, result)
            }
            "stopServer" -> {
                stopServer(result)
            }
            "isServerRunning" -> {
                result.success(webServer?.isServerRunning() ?: false)
            }
            "getServerUrl" -> {
                result.success(webServer?.getServerUrl() ?: "")
            }
            "getPairingToken" -> {
                getPairingToken(result)
            }
            "regeneratePairingToken" -> {
                regeneratePairingToken(result)
            }
            "revokeAllTokens" -> {
                revokeAllTokens(result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }
    
    private fun startServer(port: Int, result: Result) {
        try {
            if (webServer?.isServerRunning() == true) {
                result.success(true)
                return
            }
            
            // Initialize components if needed
            if (tokenManager == null) {
                tokenManager = TokenManager(context)
            }
            
            if (audioEngineBridge == null) {
                // Create MethodChannel for audio engine communication
                val audioMethodChannel = MethodChannel(
                    flutterEngine.dartExecutor.binaryMessenger,
                    "com.haasele.musicrr/audio"
                )
                audioEngineBridge = AudioEngineBridge(
                    audioMethodChannel,
                    Handler(Looper.getMainLooper())
                )
            }
            
            if (apiRouter == null) {
                apiRouter = ApiRouter(
                    tokenManager!!,
                    audioEngineBridge!!
                )
            }
            
            if (webSocketHandler == null) {
                webSocketHandler = WebSocketHandler(
                    tokenManager!!,
                    audioEngineBridge!!
                )
            }
            
            webServer = MusicrrWebServer(
                context,
                port,
                apiRouter!!,
                webSocketHandler!!
            )
            
            val success = webServer!!.startServer()
            if (success) {
                Log.i(TAG, "Remote control server started on port $port")
                result.success(true)
            } else {
                result.error("START_ERROR", "Failed to start server", null)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error starting server", e)
            result.error("START_ERROR", e.message, null)
        }
    }
    
    private fun stopServer(result: Result) {
        try {
            webServer?.stopServer()
            webServer = null
            Log.i(TAG, "Remote control server stopped")
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping server", e)
            result.error("STOP_ERROR", e.message, null)
        }
    }
    
    private fun getPairingToken(result: Result) {
        try {
            if (tokenManager == null) {
                tokenManager = TokenManager(context)
            }
            val token = tokenManager!!.getPairingToken()
            result.success(token)
        } catch (e: Exception) {
            Log.e(TAG, "Error getting pairing token", e)
            result.error("TOKEN_ERROR", e.message, null)
        }
    }
    
    private fun regeneratePairingToken(result: Result) {
        try {
            if (tokenManager == null) {
                tokenManager = TokenManager(context)
            }
            val token = tokenManager!!.regeneratePairingToken()
            result.success(token)
        } catch (e: Exception) {
            Log.e(TAG, "Error regenerating pairing token", e)
            result.error("TOKEN_ERROR", e.message, null)
        }
    }
    
    private fun revokeAllTokens(result: Result) {
        try {
            if (tokenManager == null) {
                tokenManager = TokenManager(context)
            }
            tokenManager!!.revokeAllTokens()
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error revoking tokens", e)
            result.error("TOKEN_ERROR", e.message, null)
        }
    }
}
