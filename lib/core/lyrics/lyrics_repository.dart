import 'dart:convert';
import 'package:drift/drift.dart';
import '../storage/database.dart';
import '../models/lyrics.dart';

class LyricsRepository {
  final AppDatabase _database;
  
  LyricsRepository(this._database);
  
  /// Get lyrics for a song
  Future<Lyrics?> getLyrics(String songId) async {
    final query = _database.select(_database.lyricsTable)
      ..where((l) => l.songId.equals(songId));
    final row = await query.getSingleOrNull();
    return row != null ? _lyricsFromRow(row) : null;
  }
  
  /// Save lyrics
  Future<void> saveLyrics(Lyrics lyrics) async {
    await _database.into(_database.lyricsTable).insertOnConflictUpdate(
      LyricsTableCompanion(
        id: Value(lyrics.id),
        songId: Value(lyrics.songId),
        lyricsText: Value(lyrics.lyricsText),
        lrcTimestampsJson: Value(
          lyrics.lrcLines != null
              ? jsonEncode(lyrics.lrcLines!.map((l) => l.toJson()).toList())
              : null,
        ),
        isSynced: Value(lyrics.isSynced),
        source: Value(lyrics.source),
        createdAt: Value(lyrics.createdAt),
      ),
    );
  }
  
  /// Delete lyrics
  Future<void> deleteLyrics(String songId) async {
    await (_database.delete(_database.lyricsTable)
          ..where((l) => l.songId.equals(songId)))
        .go();
  }
  
  /// Check if lyrics exist for a song
  Future<bool> hasLyrics(String songId) async {
    final query = _database.selectOnly(_database.lyricsTable)
      ..addColumns([_database.lyricsTable.id.count()])
      ..where(_database.lyricsTable.songId.equals(songId));
    final result = await query.getSingle();
    return (result.read(_database.lyricsTable.id.count()) ?? 0) > 0;
  }
  
  Lyrics _lyricsFromRow(LyricsTableData row) {
    List<LrcLine>? lrcLines;
    if (row.lrcTimestampsJson != null) {
      try {
        final jsonList = jsonDecode(row.lrcTimestampsJson!) as List;
        lrcLines = jsonList
            .map((j) => LrcLine.fromJson(j as Map<String, dynamic>))
            .toList();
      } catch (e) {
        lrcLines = null;
      }
    }
    
    return Lyrics(
      id: row.id,
      songId: row.songId,
      lyricsText: row.lyricsText,
      lrcLines: lrcLines,
      isSynced: row.isSynced,
      source: row.source,
      createdAt: row.createdAt,
    );
  }
}
