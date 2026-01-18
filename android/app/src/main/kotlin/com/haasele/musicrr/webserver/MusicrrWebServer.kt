package com.haasele.musicrr.webserver

import android.content.Context
import android.util.Log
import fi.iki.elonen.NanoHTTPD
import java.io.IOException
import java.net.InetAddress
import java.net.NetworkInterface

class MusicrrWebServer(
    private val context: Context,
    private val port: Int = 8080,
    private val apiRouter: ApiRouter,
    private val webSocketHandler: WebSocketHandler,
) : NanoHTTPD(port) {
    
    companion object {
        private const val TAG = "MusicrrWebServer"
    }
    
    private var isRunning = false
    
    override fun serve(session: IHTTPSession): Response {
        val uri = session.uri
        val method = session.method
        
        Log.d(TAG, "Request: $method $uri")
        
        // Route static files (web UI)
        if (uri.startsWith("/") && !uri.startsWith("/api/") && !uri.startsWith("/ws")) {
            return serveStaticFile(uri)
        }
        
        // Route API endpoints
        if (uri.startsWith("/api/")) {
            return apiRouter.handleRequest(session)
        }
        
        // Route WebSocket
        if (uri.startsWith("/ws")) {
            val wsResponse = webSocketHandler.handleWebSocket(session)
            if (wsResponse != null) {
                return wsResponse
            }
            // If WebSocket upgrade failed, return error
            return newFixedLengthResponse(
                Response.Status.BAD_REQUEST,
                MIME_PLAINTEXT,
                "WebSocket upgrade failed"
            )
        }
        
        // Default: serve index.html
        return serveStaticFile("/index.html")
    }
    
    private fun serveStaticFile(uri: String): Response {
        val fileName = if (uri == "/" || uri.isEmpty()) {
            "index.html"
        } else {
            uri.removePrefix("/")
        }
        
        return try {
            val inputStream = context.assets.open("web/$fileName")
            val mimeType = getMimeType(fileName)
            newFixedLengthResponse(
                Response.Status.OK,
                mimeType,
                inputStream,
                inputStream.available().toLong()
            )
        } catch (e: IOException) {
            Log.e(TAG, "Error serving static file: $fileName", e)
            newFixedLengthResponse(
                Response.Status.NOT_FOUND,
                MIME_PLAINTEXT,
                "File not found: $fileName"
            )
        }
    }
    
    private fun getMimeType(fileName: String): String {
        return when {
            fileName.endsWith(".html") -> "text/html"
            fileName.endsWith(".js") -> "application/javascript"
            fileName.endsWith(".css") -> "text/css"
            fileName.endsWith(".json") -> "application/json"
            fileName.endsWith(".png") -> "image/png"
            fileName.endsWith(".jpg") || fileName.endsWith(".jpeg") -> "image/jpeg"
            fileName.endsWith(".svg") -> "image/svg+xml"
            else -> MIME_PLAINTEXT
        }
    }
    
    fun startServer(): Boolean {
        return try {
            // Try to bind to all interfaces (0.0.0.0) for LAN access
            start(NanoHTTPD.SOCKET_READ_TIMEOUT, false)
            isRunning = true
            Log.i(TAG, "Web server started on port $port")
            Log.i(TAG, "Server URL: http://${getLocalIpAddress()}:$port")
            true
        } catch (e: IOException) {
            Log.e(TAG, "Failed to start web server", e)
            isRunning = false
            false
        }
    }
    
    fun stopServer() {
        webSocketHandler.closeAll()
        stop()
        isRunning = false
        Log.i(TAG, "Web server stopped")
    }
    
    fun getServerUrl(): String {
        return "http://${getLocalIpAddress()}:$port"
    }
    
    private fun getLocalIpAddress(): String {
        try {
            val interfaces = NetworkInterface.getNetworkInterfaces()
            while (interfaces.hasMoreElements()) {
                val networkInterface = interfaces.nextElement()
                val addresses = networkInterface.inetAddresses
                while (addresses.hasMoreElements()) {
                    val address = addresses.nextElement()
                    if (!address.isLoopbackAddress && address is java.net.Inet4Address) {
                        return address.hostAddress ?: "127.0.0.1"
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error getting local IP address", e)
        }
        return "127.0.0.1"
    }
    
    fun isServerRunning(): Boolean = isRunning
}
