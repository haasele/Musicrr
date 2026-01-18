package com.haasele.musicrr.audio

import android.media.MediaMetadataRetriever
import android.util.Log
import java.io.File

/**
 * Enhanced metadata extraction using both MediaMetadataRetriever and JAudioTagger
 */
data class AudioMetadata(
    val title: String?,
    val artist: String?,
    val album: String?,
    val albumArtist: String?,
    val genre: String?,
    val year: Int?,
    val trackNumber: Int?,
    val discNumber: Int?,
    val duration: Int?, // milliseconds
    val bitrate: Int?,
    val sampleRate: Int?,
    val channels: Int?,
    val replayGainTrack: Float?,
    val replayGainAlbum: Float?,
    val coverArtPath: String?
)

class MetadataExtractor {
    companion object {
        private const val TAG = "MetadataExtractor"
    }
    
    /**
     * Extract metadata from audio file using MediaMetadataRetriever
     */
    fun extractMetadata(filePath: String): AudioMetadata? {
        val file = File(filePath)
        if (!file.exists()) {
            Log.e(TAG, "File not found: $filePath")
            return null
        }
        
        return extractWithMediaMetadataRetriever(file)
    }
    
    /**
     * Extract metadata using MediaMetadataRetriever
     */
    private fun extractWithMediaMetadataRetriever(file: File): AudioMetadata? {
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(file.absolutePath)
            
            // Extract basic metadata
            val title = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_TITLE)
            val artist = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ARTIST)
            val album = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ALBUM)
            val albumArtist = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ALBUMARTIST)
            val genre = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_GENRE)
            val year = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_YEAR)?.toIntOrNull()
            val duration = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toIntOrNull()
            val bitrate = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_BITRATE)?.toIntOrNull()
            
            // Try to extract track number from title or other metadata
            val trackNumber = extractTrackNumber(title, album)
            
            AudioMetadata(
                title = title?.takeIf { it.isNotBlank() },
                artist = artist?.takeIf { it.isNotBlank() },
                album = album?.takeIf { it.isNotBlank() },
                albumArtist = albumArtist?.takeIf { it.isNotBlank() },
                genre = genre?.takeIf { it.isNotBlank() },
                year = year,
                trackNumber = trackNumber,
                discNumber = null, // Not available in MediaMetadataRetriever
                duration = duration,
                bitrate = bitrate,
                sampleRate = null, // Not available in MediaMetadataRetriever
                channels = null, // Not available in MediaMetadataRetriever
                replayGainTrack = null, // Not available in MediaMetadataRetriever
                replayGainAlbum = null, // Not available in MediaMetadataRetriever
                coverArtPath = null // Would need separate extraction
            )
        } catch (e: Exception) {
            Log.e(TAG, "MediaMetadataRetriever extraction failed for: ${file.name}", e)
            null
        } finally {
            retriever.release()
        }
    }
    
    /**
     * Try to extract track number from metadata
     */
    private fun extractTrackNumber(title: String?, album: String?): Int? {
        // Try to find track number in title (e.g., "01. Song Title" or "1 - Song Title")
        title?.let {
            val patterns = listOf(
                Regex("""^(\d+)[.\s-]+"""),  // "01. " or "1 - "
                Regex("""\[(\d+)\]"""),       // "[01]"
                Regex("""\((\d+)\)""")        // "(01)"
            )
            
            for (pattern in patterns) {
                val match = pattern.find(it)
                match?.groupValues?.get(1)?.toIntOrNull()?.let { trackNum ->
                    return trackNum
                }
            }
        }
        
        return null
    }
    
    /**
     * Extract embedded cover art using MediaMetadataRetriever
     */
    fun extractCoverArt(filePath: String, outputPath: String): Boolean {
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(filePath)
            
            // MediaMetadataRetriever can extract embedded artwork
            val picture = retriever.embeddedPicture
            if (picture != null) {
                File(outputPath).writeBytes(picture)
                true
            } else {
                false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error extracting cover art from: $filePath", e)
            false
        } finally {
            retriever.release()
        }
    }
}
