import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../models/lyrics.dart';
import '../storage/database.dart';
import '../storage/now_playing_preset_repository.dart';
import 'lrc_parser.dart';
import 'lyrics_repository.dart';

class LyricsService {
  final LyricsRepository _repository;
  
  LyricsService(this._repository);
  
  /// Get lyrics for a song (checks cache, embedded tags, then local files)
  Future<Lyrics?> getLyrics(Song song) async {
    // 1. Check local cache (database)
    final cached = await _repository.getLyrics(song.id);
    if (cached != null) {
      return cached;
    }
    
    // 2. Check embedded tags
    final embedded = await _getEmbeddedLyrics(song);
    if (embedded != null) {
      await _repository.saveLyrics(embedded);
      return embedded;
    }
    
    // 3. Check local LRC files
    final local = await _findLocalLrcFile(song);
    if (local != null) {
      await _repository.saveLyrics(local);
      return local;
    }
    
    return null;
  }
  
  /// Search for lyrics (user-triggered, can include online providers)
  Future<Lyrics?> searchLyrics(Song song, {bool allowOnline = false}) async {
    // First check cache
    final cached = await _repository.getLyrics(song.id);
    if (cached != null) {
      return cached;
    }
    
    // Try embedded and local first
    final embedded = await _getEmbeddedLyrics(song);
    if (embedded != null) {
      await _repository.saveLyrics(embedded);
      return embedded;
    }
    
    final local = await _findLocalLrcFile(song);
    if (local != null) {
      await _repository.saveLyrics(local);
      return local;
    }
    
    // Online search (if enabled and user consent)
    if (allowOnline) {
      // TODO: Implement online lyrics providers
      // For now, return null
    }
    
    return null;
  }
  
  /// Save lyrics manually (from user search or import)
  Future<void> saveLyrics(Lyrics lyrics) async {
    await _repository.saveLyrics(lyrics);
  }
  
  /// Delete lyrics for a song
  Future<void> deleteLyrics(String songId) async {
    await _repository.deleteLyrics(songId);
  }
  
  /// Get embedded lyrics from audio file tags
  Future<Lyrics?> _getEmbeddedLyrics(Song song) async {
    try {
      // Use metadata extractor to get embedded lyrics
      // This would need to be implemented in the native side
      // For now, return null as placeholder
      return null;
    } catch (e) {
      return null;
    }
  }
  
  /// Find local LRC file for a song
  Future<Lyrics?> _findLocalLrcFile(Song song) async {
    try {
      // Try to find LRC file next to audio file
      final audioFile = File(song.uri);
      if (!await audioFile.exists()) {
        return null;
      }
      
      final audioDir = audioFile.parent;
      final audioName = p.basenameWithoutExtension(audioFile.path);
      
      // Try common LRC file names
      final lrcNames = [
        '$audioName.lrc',
        '${p.basename(audioFile.path)}.lrc',
        '${song.title}.lrc',
        '${song.artist} - ${song.title}.lrc',
      ];
      
      for (final lrcName in lrcNames) {
        final lrcFile = File(p.join(audioDir.path, lrcName));
        if (await lrcFile.exists()) {
          final content = await lrcFile.readAsBytes();
          final lyrics = LrcParser.parseLrcFromBytes(
            content,
            song.id,
            source: 'local',
          );
          if (lyrics != null) {
            return lyrics;
          }
        }
      }
      
      // Also check parent directory (common for organized libraries)
      final parentDir = audioDir.parent;
      for (final lrcName in lrcNames) {
        final lrcFile = File(p.join(parentDir.path, lrcName));
        if (await lrcFile.exists()) {
          final content = await lrcFile.readAsBytes();
          final lyrics = LrcParser.parseLrcFromBytes(
            content,
            song.id,
            source: 'local',
          );
          if (lyrics != null) {
            return lyrics;
          }
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
  
  /// Get lyrics line at current playback position
  Future<String?> getCurrentLine(Lyrics lyrics, int positionMs) async {
    if (!lyrics.isSynced || lyrics.lrcLines == null || lyrics.lrcLines!.isEmpty) {
      return null;
    }
    
    return LrcParser.getLineAtTimestamp(lyrics.lrcLines!, positionMs);
  }
  
  /// Get all lyrics lines up to current position
  Future<List<String>> getLinesUpTo(Lyrics lyrics, int positionMs) async {
    if (!lyrics.isSynced || lyrics.lrcLines == null || lyrics.lrcLines!.isEmpty) {
      return lyrics.lyricsText.split('\n');
    }
    
    return LrcParser.getLinesUpToTimestamp(lyrics.lrcLines!, positionMs);
  }
}

final lyricsServiceProvider = Provider<LyricsService>((ref) {
  final database = ref.watch(appDatabaseProvider);
  final repository = LyricsRepository(database);
  return LyricsService(repository);
});
