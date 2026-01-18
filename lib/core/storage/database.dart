import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

// Now Playing Presets Table
class NowPlayingPresets extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get layoutJson => text()(); // JSON string of layout configuration
  TextColumn get backgroundConfigJson => text()(); // JSON string of background config
  TextColumn get scope => text()(); // 'global', 'provider', 'album'
  TextColumn get sourceId => text().nullable()(); // Provider ID or album ID if scope is provider/album
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastModified => dateTime().nullable()();
  
  @override
  Set<Column> get primaryKey => {id};
}

// Lyrics Table
class LyricsTable extends Table {
  TextColumn get id => text()();
  TextColumn get songId => text()();
  TextColumn get lyricsText => text()();
  TextColumn get lrcTimestampsJson => text().nullable()(); // JSON array of timestamped lyrics
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  TextColumn get source => text().nullable()(); // 'local', 'embedded', 'online'
  DateTimeColumn get createdAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}

// Playback Analytics Table
class PlaybackAnalytics extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get songId => text()();
  DateTimeColumn get playedAt => dateTime()();
  IntColumn get durationMs => integer()(); // How long the song was played
  BoolColumn get completed => boolean().withDefault(const Constant(false))(); // Was song played to completion
  BoolColumn get skipped => boolean().withDefault(const Constant(false))(); // Was song skipped
  IntColumn get skipPositionMs => integer().nullable()(); // Position when skipped
}

// Downloads Table
class Downloads extends Table {
  TextColumn get id => text()();
  TextColumn get songId => text()();
  TextColumn get providerId => text()();
  TextColumn get status => text()(); // 'pending', 'downloading', 'completed', 'failed'
  IntColumn get progress => integer().withDefault(const Constant(0))(); // 0-100
  TextColumn get localPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  
  @override
  Set<Column> get primaryKey => {id};
}

// Cache Metadata Table
class CacheMetadata extends Table {
  TextColumn get id => text()();
  TextColumn get songId => text()();
  TextColumn get providerId => text()();
  TextColumn get cachePath => text()();
  IntColumn get fileSizeBytes => integer()();
  DateTimeColumn get cachedAt => dateTime()();
  DateTimeColumn get lastAccessed => dateTime()();
  IntColumn get accessCount => integer().withDefault(const Constant(0))();
  IntColumn get priority => integer().withDefault(const Constant(0))(); // Higher = more important
  
  @override
  Set<Column> get primaryKey => {id};
}

// Queue Snapshots Table
class QueueSnapshots extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().nullable()(); // Optional name for saved queue
  TextColumn get queueJson => text()(); // JSON array of song IDs
  IntColumn get currentIndex => integer().withDefault(const Constant(0))();
  BoolColumn get shuffleEnabled => boolean().withDefault(const Constant(false))();
  TextColumn get repeatMode => text().withDefault(const Constant('none'))(); // 'none', 'one', 'all'
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isTemporary => boolean().withDefault(const Constant(true))(); // Temporary queues are cleared on app close
  
  @override
  Set<Column> get primaryKey => {id};
}

// User Playlists Table
class UserPlaylists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get songIdsJson => text()(); // JSON array of song IDs
  TextColumn get coverArtUri => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastModified => dateTime().nullable()();
  
  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [
  NowPlayingPresets,
  LyricsTable,
  PlaybackAnalytics,
  Downloads,
  CacheMetadata,
  QueueSnapshots,
  UserPlaylists,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Add UserPlaylists table
          await m.createTable(userPlaylists);
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'musicrr.db'));
    return NativeDatabase(file);
  });
}
