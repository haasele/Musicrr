import 'package:flutter/services.dart';

/// Metadata extracted from audio file
class AudioMetadata {
  final String? title;
  final String? artist;
  final String? album;
  final String? albumArtist;
  final String? genre;
  final int? year;
  final int? trackNumber;
  final int? discNumber;
  final int? duration; // milliseconds
  final int? bitrate;
  final int? sampleRate;
  final int? channels;
  final double? replayGainTrack;
  final double? replayGainAlbum;
  final String? coverArtPath;

  const AudioMetadata({
    this.title,
    this.artist,
    this.album,
    this.albumArtist,
    this.genre,
    this.year,
    this.trackNumber,
    this.discNumber,
    this.duration,
    this.bitrate,
    this.sampleRate,
    this.channels,
    this.replayGainTrack,
    this.replayGainAlbum,
    this.coverArtPath,
  });

  factory AudioMetadata.fromMap(Map<String, dynamic> map) {
    return AudioMetadata(
      title: map['title'] as String?,
      artist: map['artist'] as String?,
      album: map['album'] as String?,
      albumArtist: map['albumArtist'] as String?,
      genre: map['genre'] as String?,
      year: map['year'] as int?,
      trackNumber: map['trackNumber'] as int?,
      discNumber: map['discNumber'] as int?,
      duration: map['duration'] as int?,
      bitrate: map['bitrate'] as int?,
      sampleRate: map['sampleRate'] as int?,
      channels: map['channels'] as int?,
      replayGainTrack: (map['replayGainTrack'] as num?)?.toDouble(),
      replayGainAlbum: (map['replayGainAlbum'] as num?)?.toDouble(),
      coverArtPath: map['coverArtPath'] as String?,
    );
  }
}

/// Service for extracting metadata from audio files
class MetadataExtractor {
  static const MethodChannel _channel = MethodChannel('com.haasele.musicrr/metadata');

  /// Extract metadata from audio file
  static Future<AudioMetadata?> extractMetadata(String filePath) async {
    try {
      final result = await _channel.invokeMethod('extractMetadata', {
        'filePath': filePath,
      });
      
      if (result == null) return null;
      return AudioMetadata.fromMap(Map<String, dynamic>.from(result));
    } on PlatformException catch (e) {
      print('Error extracting metadata: ${e.message}');
      return null;
    }
  }

  /// Extract cover art from audio file
  static Future<String?> extractCoverArt(String filePath, String outputPath) async {
    try {
      final result = await _channel.invokeMethod('extractCoverArt', {
        'filePath': filePath,
        'outputPath': outputPath,
      });
      return result as String?;
    } on PlatformException catch (e) {
      print('Error extracting cover art: ${e.message}');
      return null;
    }
  }
}
