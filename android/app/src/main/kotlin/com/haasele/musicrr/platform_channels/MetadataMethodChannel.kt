package com.haasele.musicrr.platform_channels

import android.util.Log
import com.haasele.musicrr.audio.MetadataExtractor
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MetadataMethodChannel(flutterEngine: FlutterEngine) {
    companion object {
        private const val CHANNEL_NAME = "com.haasele.musicrr/metadata"
        private const val TAG = "MetadataMethodChannel"
    }
    
    private val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
    private val metadataExtractor = MetadataExtractor()
    
    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "extractMetadata" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath == null) {
                        result.error("INVALID_ARGUMENT", "filePath is required", null)
                        return@setMethodCallHandler
                    }
                    
                    try {
                        val metadata = metadataExtractor.extractMetadata(filePath)
                        if (metadata != null) {
                            result.success(mapOf(
                                "title" to metadata.title,
                                "artist" to metadata.artist,
                                "album" to metadata.album,
                                "albumArtist" to metadata.albumArtist,
                                "genre" to metadata.genre,
                                "year" to metadata.year,
                                "trackNumber" to metadata.trackNumber,
                                "discNumber" to metadata.discNumber,
                                "duration" to metadata.duration,
                                "bitrate" to metadata.bitrate,
                                "sampleRate" to metadata.sampleRate,
                                "channels" to metadata.channels,
                                "replayGainTrack" to metadata.replayGainTrack,
                                "replayGainAlbum" to metadata.replayGainAlbum,
                                "coverArtPath" to metadata.coverArtPath,
                            ))
                        } else {
                            result.success(null)
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Error extracting metadata", e)
                        result.error("EXTRACTION_ERROR", e.message, null)
                    }
                }
                "extractCoverArt" -> {
                    val filePath = call.argument<String>("filePath")
                    val outputPath = call.argument<String>("outputPath")
                    
                    if (filePath == null || outputPath == null) {
                        result.error("INVALID_ARGUMENT", "filePath and outputPath are required", null)
                        return@setMethodCallHandler
                    }
                    
                    try {
                        val success = metadataExtractor.extractCoverArt(filePath, outputPath)
                        if (success) {
                            result.success(outputPath)
                        } else {
                            result.success(null)
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Error extracting cover art", e)
                        result.error("EXTRACTION_ERROR", e.message, null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
