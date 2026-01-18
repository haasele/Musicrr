import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/database.dart';
import '../storage/now_playing_preset_repository.dart';
import '../models/song.dart';

class AnalyticsService {
  final AppDatabase _database;
  
  AnalyticsService(this._database);
  
  /// Record play event
  Future<void> recordPlayEvent({
    required String songId,
    required int durationMs,
    required bool completed,
    required bool skipped,
    int? skipPositionMs,
  }) async {
    await _database.into(_database.playbackAnalytics).insert(
      PlaybackAnalyticsCompanion.insert(
        songId: songId,
        playedAt: DateTime.now(),
        durationMs: durationMs,
        completed: Value(completed),
        skipped: Value(skipped),
        skipPositionMs: Value(skipPositionMs),
      ),
    );
  }
  
  /// Get play frequency for a song
  Future<int> getPlayFrequency(String songId) async {
    final query = _database.selectOnly(_database.playbackAnalytics)
      ..addColumns([_database.playbackAnalytics.id.count()])
      ..where(_database.playbackAnalytics.songId.equals(songId));
    final result = await query.getSingle();
    return result.read(_database.playbackAnalytics.id.count()) ?? 0;
  }
  
  /// Get last played time for a song
  Future<DateTime?> getLastPlayed(String songId) async {
    final query = _database.select(_database.playbackAnalytics)
      ..where((a) => a.songId.equals(songId))
      ..orderBy([(a) => OrderingTerm.desc(a.playedAt)])
      ..limit(1);
    final result = await query.getSingleOrNull();
    return result?.playedAt;
  }
  
  /// Get skip rate for a song (0.0 to 1.0)
  Future<double> getSkipRate(String songId) async {
    final allEvents = await (_database.select(_database.playbackAnalytics)
          ..where((a) => a.songId.equals(songId)))
        .get();
    
    if (allEvents.isEmpty) return 0.0;
    
    final total = allEvents.length;
    final skipped = allEvents.where((e) => e.skipped).length;
    
    return skipped / total;
  }
  
  /// Get completion rate for a song (0.0 to 1.0)
  Future<double> getCompletionRate(String songId) async {
    final allEvents = await (_database.select(_database.playbackAnalytics)
          ..where((a) => a.songId.equals(songId)))
        .get();
    
    if (allEvents.isEmpty) return 0.0;
    
    final total = allEvents.length;
    final completed = allEvents.where((e) => e.completed).length;
    
    return completed / total;
  }
  
  /// Get average play duration for a song
  Future<int> getAverageDuration(String songId) async {
    final query = _database.selectOnly(_database.playbackAnalytics)
      ..addColumns([_database.playbackAnalytics.durationMs.avg()])
      ..where(_database.playbackAnalytics.songId.equals(songId));
    final result = await query.getSingle();
    final avg = result.read(_database.playbackAnalytics.durationMs.avg());
    return avg?.toInt() ?? 0;
  }
  
  /// Get recently played songs (within last N days)
  Future<List<String>> getRecentlyPlayedSongIds(int days) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final query = _database.select(_database.playbackAnalytics)
      ..where((a) => a.playedAt.isBiggerThanValue(cutoffDate))
      ..orderBy([(a) => OrderingTerm.desc(a.playedAt)]);
    final results = await query.get();
    return results.map((r) => r.songId).toSet().toList();
  }
  
  /// Get most played songs (top N by frequency)
  Future<List<String>> getMostPlayedSongIds(int limit) async {
    // Get all events and count manually since drift's groupBy with orderBy is complex
    final allEvents = await _database.select(_database.playbackAnalytics).get();
    final songCounts = <String, int>{};
    
    for (final event in allEvents) {
      songCounts[event.songId] = (songCounts[event.songId] ?? 0) + 1;
    }
    
    final sortedSongs = songCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedSongs
        .take(limit)
        .map((e) => e.key)
        .toList();
  }
  
  /// Get songs with high skip rate
  Future<List<String>> getHighSkipRateSongIds(double threshold, int minPlays) async {
    // This requires a more complex query - simplified for now
    final allSongs = await _database.select(_database.playbackAnalytics)
        .get();
    final songStats = <String, Map<String, int>>{};
    
    for (final event in allSongs) {
      final stats = songStats.putIfAbsent(event.songId, () => {
        'total': 0,
        'skipped': 0,
      });
      stats['total'] = (stats['total'] ?? 0) + 1;
      if (event.skipped) {
        stats['skipped'] = (stats['skipped'] ?? 0) + 1;
      }
    }
    
    return songStats.entries
        .where((entry) {
          final stats = entry.value;
          final total = stats['total'] ?? 0;
          final skipped = stats['skipped'] ?? 0;
          return total >= minPlays && (skipped / total) >= threshold;
        })
        .map((entry) => entry.key)
        .toList();
  }
}

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return AnalyticsService(database);
});
