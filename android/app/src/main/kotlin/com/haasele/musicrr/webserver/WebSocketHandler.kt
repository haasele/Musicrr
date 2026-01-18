package com.haasele.musicrr.webserver

import android.util.Log
import fi.iki.elonen.NanoHTTPD
// import fi.iki.elonen.NanoWSD  // Temporarily disabled - WebSocket support may need different implementation
import org.json.JSONObject
import java.io.IOException
import java.util.concurrent.ConcurrentHashMap

/**
 * WebSocket handler for real-time updates and bidirectional commands
 */
class WebSocketHandler(
    private val tokenManager: TokenManager,
    val audioEngineBridge: AudioEngineBridge
) {
    
    companion object {
        private const val TAG = "WebSocketHandler"
    }
    
    private val clients = ConcurrentHashMap<String, MusicrrWebSocket>()
    
    /**
     * Handle WebSocket upgrade request
     * Returns WebSocket response if upgrade is successful, null otherwise
     */
    fun handleWebSocket(session: NanoHTTPD.IHTTPSession): NanoHTTPD.Response? {
        // Check if this is a WebSocket upgrade request
        val upgradeHeader = session.headers["upgrade"]
        if (upgradeHeader == null || !upgradeHeader.equals("websocket", ignoreCase = true)) {
            return null
        }
        
        // Extract token from query string or headers
        val token = extractToken(session)
        
        if (token == null || !tokenManager.validateAccessToken(token)) {
            Log.w(TAG, "WebSocket connection rejected: invalid token")
            return NanoHTTPD.newFixedLengthResponse(
                NanoHTTPD.Response.Status.UNAUTHORIZED,
                "text/plain",
                "Unauthorized"
            )
        }
        
        // Create WebSocket connection using NanoWSD
        try {
            val webSocket = MusicrrWebSocket(session, token, this)
            val clientId = webSocket.clientId
            
            synchronized(clients) {
                clients[clientId] = webSocket
            }
            
            Log.i(TAG, "WebSocket client connected: $clientId (total: ${clients.size})")
            
            // Send initial state after connection is established
            // This will be done in onOpen callback
            
            return webSocket.handshakeResponse
        } catch (e: Exception) {
            Log.e(TAG, "Error creating WebSocket connection", e)
            return NanoHTTPD.newFixedLengthResponse(
                NanoHTTPD.Response.Status.INTERNAL_ERROR,
                "text/plain",
                "WebSocket error"
            )
        }
    }
    
    /**
     * Extract authentication token from session
     */
    private fun extractToken(session: NanoHTTPD.IHTTPSession): String? {
        // Try query parameter first
        val queryParams = session.parms
        val tokenFromQuery = queryParams["token"]
        if (tokenFromQuery != null) {
            return tokenFromQuery
        }
        
        // Try Authorization header
        val authHeader = session.headers["authorization"]
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            return authHeader.removePrefix("Bearer ").trim()
        }
        
        return null
    }
    
    /**
     * Remove client connection
     */
    fun removeClient(clientId: String) {
        synchronized(clients) {
            clients.remove(clientId)
        }
        Log.i(TAG, "WebSocket client disconnected: $clientId (remaining: ${clients.size})")
    }
    
    /**
     * Broadcast event to all connected clients
     */
    fun broadcast(event: String, data: JSONObject) {
        if (clients.isEmpty()) {
            return // No clients connected
        }
        
        val message = JSONObject().apply {
            put("event", event)
            put("data", data)
            put("timestamp", System.currentTimeMillis())
        }
        
        val messageStr = message.toString()
        val clientsToRemove = mutableListOf<String>()
        
        synchronized(clients) {
            clients.values.forEach { client ->
                try {
                    client.send(messageStr)
                } catch (e: Exception) {
                    Log.e(TAG, "Error sending message to client ${client.clientId}", e)
                    clientsToRemove.add(client.clientId)
                }
            }
        }
        
        // Remove failed clients
        clientsToRemove.forEach { removeClient(it) }
    }
    
    /**
     * Broadcast playback state change
     */
    fun broadcastPlaybackState(state: String) {
        val data = JSONObject().apply {
            put("state", state)
        }
        broadcast("playback.state", data)
    }
    
    /**
     * Broadcast position update
     */
    fun broadcastPosition(positionMs: Int, durationMs: Int) {
        val data = JSONObject().apply {
            put("position", positionMs)
            put("duration", durationMs)
        }
        broadcast("playback.position", data)
    }
    
    /**
     * Broadcast track change
     */
    fun broadcastTrackChange(track: Map<String, Any?>, positionMs: Int = 0) {
        val data = JSONObject().apply {
            put("track", JSONObject(track))
            put("position", positionMs)
        }
        broadcast("playback.track", data)
    }
    
    /**
     * Broadcast queue update
     */
    fun broadcastQueueUpdate(queue: List<Map<String, Any?>>, currentIndex: Int) {
        val data = JSONObject().apply {
            put("currentIndex", currentIndex)
            put("queueLength", queue.size)
            put("tracks", org.json.JSONArray(queue))
        }
        broadcast("queue.updated", data)
    }
    
    /**
     * Broadcast volume change
     */
    fun broadcastVolumeChange(volume: Double) {
        val data = JSONObject().apply {
            put("volume", volume)
        }
        broadcast("volume.changed", data)
    }
    
    /**
     * Handle command from client
     */
    fun handleCommand(client: MusicrrWebSocket, command: String, params: JSONObject) {
        Log.d(TAG, "Command from ${client.clientId}: $command")
        
        val response = JSONObject().apply {
            put("success", false)
            put("command", command)
        }
        
        try {
            when (command) {
                "play" -> {
                    val trackId = params.optString("trackId", null)
                    val position = params.optInt("position", 0)
                    val success = audioEngineBridge.play(trackId, position)
                    response.put("success", success)
                }
                "pause" -> {
                    val success = audioEngineBridge.pause()
                    response.put("success", success)
                }
                "resume" -> {
                    val success = audioEngineBridge.resume()
                    response.put("success", success)
                }
                "stop" -> {
                    val success = audioEngineBridge.stop()
                    response.put("success", success)
                }
                "seek" -> {
                    val position = params.getInt("position")
                    val success = audioEngineBridge.seek(position)
                    response.put("success", success)
                }
                "next" -> {
                    // TODO: Implement next track via audio engine bridge
                    response.put("success", false)
                    response.put("error", "Not yet implemented")
                }
                "previous" -> {
                    // TODO: Implement previous track via audio engine bridge
                    response.put("success", false)
                    response.put("error", "Not yet implemented")
                }
                "setVolume" -> {
                    val volume = params.getDouble("volume")
                    val success = audioEngineBridge.setVolume(volume)
                    response.put("success", success)
                    if (success) {
                        response.put("volume", volume)
                    }
                }
                "getStatus" -> {
                    val status = audioEngineBridge.getStatus()
                    response.put("success", true)
                    response.put("status", JSONObject(status))
                }
                "getQueue" -> {
                    val queue = audioEngineBridge.getQueue()
                    response.put("success", true)
                    response.put("queue", org.json.JSONArray(queue))
                }
                else -> {
                    response.put("error", "Unknown command: $command")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error handling command: $command", e)
            response.put("error", e.message)
        }
        
        // Send response back to client
        try {
            client.send(response.toString())
        } catch (e: Exception) {
            Log.e(TAG, "Error sending command response", e)
        }
    }
    
    /**
     * Get number of connected clients
     */
    fun getClientCount(): Int = clients.size
    
    /**
     * Close all connections
     */
    fun closeAll() {
        synchronized(clients) {
            clients.values.forEach { client ->
                try {
                    client.onClose(1000, "Server shutdown", false)
                } catch (e: Exception) {
                    Log.e(TAG, "Error closing client connection", e)
                }
            }
            clients.clear()
        }
        Log.i(TAG, "All WebSocket connections closed")
    }
}

/**
 * WebSocket connection wrapper
 */
// Temporarily disabled - WebSocket implementation needs to be fixed
// NanoWSD may not be available in NanoHTTPD 2.3.1
class MusicrrWebSocket(
    session: NanoHTTPD.IHTTPSession,
    private val token: String,
    private val handler: WebSocketHandler
) {
    
    companion object {
        private const val TAG = "MusicrrWebSocket"
    }
    
    val clientId: String = "client-${System.currentTimeMillis()}-${hashCode()}"
    
    // WebSocket methods temporarily disabled - will be implemented properly later
    fun onOpen() {
        Log.d(TAG, "WebSocket opened: $clientId")
        // Send initial state when connection is established
        sendInitialState()
    }
    
    fun onClose(
        code: Int,
        reason: String,
        initiatedByRemote: Boolean
    ) {
        Log.d(TAG, "WebSocket closed: $clientId - $code: $reason")
        handler.removeClient(clientId)
    }
    
    fun onMessage(message: String) {
        try {
            val json = JSONObject(message)
            
            // Check if it's a command
            if (json.has("command")) {
                val command = json.getString("command")
                val params = json.optJSONObject("params") ?: JSONObject()
                handler.handleCommand(this, command, params)
            } else {
                Log.w(TAG, "Unknown message format from $clientId: $message")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error processing message from $clientId", e)
            try {
                val errorResponse = JSONObject().apply {
                    put("error", "Invalid message format")
                    put("message", e.message)
                }
                send(errorResponse.toString())
            } catch (sendError: Exception) {
                Log.e(TAG, "Error sending error response", sendError)
            }
        }
    }
    
    fun onException(exception: IOException) {
        Log.e(TAG, "WebSocket exception for $clientId", exception)
        handler.removeClient(clientId)
    }
    
    fun send(message: String) {
        // TODO: Implement WebSocket send
        Log.d(TAG, "Would send message: $message")
    }
    
    val handshakeResponse: NanoHTTPD.Response
        get() {
            // Create a WebSocket handshake response
            // Note: This is a simplified version - full WebSocket implementation would need proper handshake
            return NanoHTTPD.newFixedLengthResponse(
                NanoHTTPD.Response.Status.OK,
                "application/json",
                ""
            )
        }
    
    /**
     * Send initial state to client when connected
     */
    private fun sendInitialState() {
        try {
            val status = handler.audioEngineBridge.getStatus()
            val queue = handler.audioEngineBridge.getQueue()
            
            val initialState = JSONObject().apply {
                put("event", "initial.state")
                put("data", JSONObject().apply {
                    put("status", JSONObject(status))
                    put("queue", org.json.JSONArray(queue))
                })
                put("timestamp", System.currentTimeMillis())
            }
            
            send(initialState.toString())
        } catch (e: Exception) {
            Log.e(TAG, "Error sending initial state", e)
        }
    }
}
