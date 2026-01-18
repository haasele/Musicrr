import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/database.dart';
import '../storage/now_playing_preset_repository.dart';
import '../models/song.dart';
import 'playback_queue.dart';

class QueuePersistence {
  final AppDatabase _database;
  
  QueuePersistence(this._database);
  
  /// Save queue to database
  Future<void> saveQueue(PlaybackQueue queue, {String? name, bool isTemporary = true}) async {
    final queueId = 'queue_${DateTime.now().millisecondsSinceEpoch}';
    final songIds = queue.tracks.map((s) => s.id).toList();
    
    await _database.into(_database.queueSnapshots).insert(
      QueueSnapshotsCompanion.insert(
        id: queueId,
        name: Value(name),
        queueJson: jsonEncode(songIds),
        currentIndex: Value(queue.currentIndex),
        shuffleEnabled: Value(queue.shuffleEnabled),
        repeatMode: Value(queue.repeatMode.name),
        createdAt: DateTime.now(),
        isTemporary: Value(isTemporary),
      ),
    );
  }
  
  /// Restore queue from database
  Future<QueueSnapshot?> restoreQueue(String queueId, Future<List<Song>> Function(List<String>) songIds) async {
    final query = _database.select(_database.queueSnapshots)
      ..where((q) => q.id.equals(queueId));
    final row = await query.getSingleOrNull();
    
    if (row == null) return null;
    
    final songIdsList = List<String>.from(jsonDecode(row.queueJson) as List);
    final songs = await songIds(songIdsList);
    
    return QueueSnapshot(
      id: row.id,
      name: row.name,
      songs: songs,
      currentIndex: row.currentIndex,
      shuffleEnabled: row.shuffleEnabled,
      repeatMode: _parseRepeatMode(row.repeatMode),
    );
  }
  
  /// Get temporary queue (for restoring on app start)
  Future<QueueSnapshot?> getTemporaryQueue(Future<List<Song>> Function(List<String>) songIds) async {
    final query = _database.select(_database.queueSnapshots)
      ..where((q) => q.isTemporary.equals(true))
      ..orderBy([(q) => OrderingTerm.desc(q.createdAt)])
      ..limit(1);
    final row = await query.getSingleOrNull();
    
    if (row == null) return null;
    
    final songIdsList = List<String>.from(jsonDecode(row.queueJson) as List);
    final songs = await songIds(songIdsList);
    
    return QueueSnapshot(
      id: row.id,
      name: row.name,
      songs: songs,
      currentIndex: row.currentIndex,
      shuffleEnabled: row.shuffleEnabled,
      repeatMode: _parseRepeatMode(row.repeatMode),
    );
  }
  
  /// Save queue as playlist
  Future<String> saveQueueAsPlaylist(PlaybackQueue queue, String playlistName) async {
    final playlistId = 'playlist_${DateTime.now().millisecondsSinceEpoch}';
    final songIds = queue.tracks.map((s) => s.id).toList();
    
    // Save as non-temporary queue (acts as playlist)
    await _database.into(_database.queueSnapshots).insert(
      QueueSnapshotsCompanion.insert(
        id: playlistId,
        name: Value(playlistName),
        queueJson: jsonEncode(songIds),
        currentIndex: const Value(0),
        shuffleEnabled: const Value(false),
        repeatMode: const Value('none'),
        createdAt: DateTime.now(),
        isTemporary: const Value(false),
      ),
    );
    
    return playlistId;
  }
  
  /// Clear temporary queues
  Future<void> clearTemporaryQueues() async {
    await (_database.delete(_database.queueSnapshots)
          ..where((q) => q.isTemporary.equals(true)))
        .go();
  }
  
  RepeatMode _parseRepeatMode(String mode) {
    switch (mode) {
      case 'one':
        return RepeatMode.one;
      case 'all':
        return RepeatMode.all;
      default:
        return RepeatMode.none;
    }
  }
}

class QueueSnapshot {
  final String id;
  final String? name;
  final List<Song> songs;
  final int currentIndex;
  final bool shuffleEnabled;
  final RepeatMode repeatMode;
  
  QueueSnapshot({
    required this.id,
    this.name,
    required this.songs,
    required this.currentIndex,
    required this.shuffleEnabled,
    required this.repeatMode,
  });
}

final queuePersistenceProvider = Provider<QueuePersistence>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return QueuePersistence(database);
});
