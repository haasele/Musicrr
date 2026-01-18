package com.haasele.musicrr.webserver

import android.util.Log
import fi.iki.elonen.NanoHTTPD
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader

class ApiRouter(
    private val tokenManager: TokenManager,
    private val audioEngineBridge: AudioEngineBridge,
) {
    
    companion object {
        private const val TAG = "ApiRouter"
    }
    
    fun handleRequest(session: NanoHTTPD.IHTTPSession): NanoHTTPD.Response {
        val uri = session.uri
        val method = session.method
        
        Log.d(TAG, "API Request: $method $uri")
        
        // Handle info endpoint (no auth required)
        if (uri == "/api/info") {
            return handleInfo()
        }
        
        // Handle pairing endpoint (no auth required)
        if (uri == "/api/pair" && method == NanoHTTPD.Method.POST) {
            return handlePairing(session)
        }
        
        // All other endpoints require authentication
        val authHeader = session.headers["authorization"]
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            return createErrorResponse(401, "INVALID_TOKEN", "Authentication required")
        }
        
        val token = authHeader.removePrefix("Bearer ").trim()
        if (!tokenManager.validateAccessToken(token)) {
            return createErrorResponse(401, "INVALID_TOKEN", "Invalid or expired token")
        }
        
        // Route authenticated requests
        return when {
            uri == "/api/status" && method == NanoHTTPD.Method.GET -> handleStatus()
            uri == "/api/play" && method == NanoHTTPD.Method.POST -> handlePlay(session)
            uri == "/api/pause" && method == NanoHTTPD.Method.POST -> handlePause()
            uri == "/api/resume" && method == NanoHTTPD.Method.POST -> handleResume()
            uri == "/api/stop" && method == NanoHTTPD.Method.POST -> handleStop()
            uri == "/api/seek" && method == NanoHTTPD.Method.POST -> handleSeek(session)
            uri == "/api/queue" && method == NanoHTTPD.Method.GET -> handleGetQueue()
            uri == "/api/volume" && method == NanoHTTPD.Method.GET -> handleGetVolume()
            uri == "/api/volume" && method == NanoHTTPD.Method.POST -> handleSetVolume(session)
            else -> createErrorResponse(404, "NOT_FOUND", "Endpoint not found: $uri")
        }
    }
    
    private fun handleInfo(): NanoHTTPD.Response {
        val response = JSONObject().apply {
            put("name", "Musicrr")
            put("version", "1.0.0")
            put("serverId", "musicrr-device-1")
            put("requiresAuth", true)
            put("pairingEnabled", true)
        }
        return createJsonResponse(200, response.toString())
    }
    
    private fun handlePairing(session: NanoHTTPD.IHTTPSession): NanoHTTPD.Response {
        val body = readRequestBody(session)
        val pairingToken = JSONObject(body).optString("pairingToken", "")
        
        val accessToken = tokenManager.validatePairingToken(pairingToken)
        if (accessToken == null) {
            return createErrorResponse(401, "INVALID_TOKEN", "Invalid pairing token")
        }
        
        val response = JSONObject().apply {
            put("success", true)
            put("accessToken", accessToken)
            put("expiresIn", 31536000) // 1 year in seconds
        }
        return createJsonResponse(200, response.toString())
    }
    
    private fun handleStatus(): NanoHTTPD.Response {
        val status = audioEngineBridge.getStatus()
        val response = JSONObject(status)
        return createJsonResponse(200, response.toString())
    }
    
    private fun handlePlay(session: NanoHTTPD.IHTTPSession): NanoHTTPD.Response {
        val body = readRequestBody(session)
        val json = JSONObject(body)
        val trackId = json.optString("trackId", null)
        val position = json.optInt("position", 0)
        
        val success = audioEngineBridge.play(trackId, position)
        val response = JSONObject().apply {
            put("success", success)
        }
        return createJsonResponse(200, response.toString())
    }
    
    private fun handlePause(): NanoHTTPD.Response {
        val success = audioEngineBridge.pause()
        val response = JSONObject().apply {
            put("success", success)
        }
        return createJsonResponse(200, response.toString())
    }
    
    private fun handleResume(): NanoHTTPD.Response {
        val success = audioEngineBridge.resume()
        val response = JSONObject().apply {
            put("success", success)
        }
        return createJsonResponse(200, response.toString())
    }
    
    private fun handleStop(): NanoHTTPD.Response {
        val success = audioEngineBridge.stop()
        val response = JSONObject().apply {
            put("success", success)
        }
        return createJsonResponse(200, response.toString())
    }
    
    private fun handleSeek(session: NanoHTTPD.IHTTPSession): NanoHTTPD.Response {
        val body = readRequestBody(session)
        val json = JSONObject(body)
        val position = json.getInt("position")
        
        val success = audioEngineBridge.seek(position)
        val response = JSONObject().apply {
            put("success", success)
            put("position", position)
        }
        return createJsonResponse(200, response.toString())
    }
    
    private fun handleGetQueue(): NanoHTTPD.Response {
        val queue = audioEngineBridge.getQueue()
        val response = JSONObject().apply {
            put("currentIndex", 0) // TODO: Get from audio engine
            put("tracks", queue)
        }
        return createJsonResponse(200, response.toString())
    }
    
    private fun handleGetVolume(): NanoHTTPD.Response {
        val status = audioEngineBridge.getStatus()
        val volume = status["volume"] as? Double ?: 1.0
        val response = JSONObject().apply {
            put("volume", volume)
        }
        return createJsonResponse(200, response.toString())
    }
    
    private fun handleSetVolume(session: NanoHTTPD.IHTTPSession): NanoHTTPD.Response {
        val body = readRequestBody(session)
        val json = JSONObject(body)
        val volume = json.getDouble("volume")
        
        val success = audioEngineBridge.setVolume(volume)
        val response = JSONObject().apply {
            put("success", success)
            put("volume", volume)
        }
        return createJsonResponse(200, response.toString())
    }
    
    private fun readRequestBody(session: NanoHTTPD.IHTTPSession): String {
        return try {
            val reader = BufferedReader(InputStreamReader(session.inputStream))
            reader.readText()
        } catch (e: Exception) {
            Log.e(TAG, "Error reading request body", e)
            "{}"
        }
    }
    
    private fun createJsonResponse(status: Int, json: String): NanoHTTPD.Response {
        return NanoHTTPD.newFixedLengthResponse(
            NanoHTTPD.Response.Status.lookup(status),
            "application/json",
            json
        )
    }
    
    private fun createErrorResponse(status: Int, code: String, message: String): NanoHTTPD.Response {
        val error = JSONObject().apply {
            put("error", message)
            put("code", code)
        }
        return createJsonResponse(status, error.toString())
    }
}
