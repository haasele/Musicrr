import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/database.dart';
import '../storage/now_playing_preset_repository.dart';
import '../models/song.dart';
import '../providers/media_provider.dart';
import '../providers/provider_repository.dart';

enum DownloadStatus {
  pending,
  downloading,
  completed,
  failed,
  cancelled,
}

class DownloadTask {
  final String id;
  final String songId;
  final String providerId;
  final DownloadStatus status;
  final int progress; // 0-100
  final String? localPath;
  final String? error;
  final DateTime createdAt;
  final DateTime? completedAt;
  
  const DownloadTask({
    required this.id,
    required this.songId,
    required this.providerId,
    this.status = DownloadStatus.pending,
    this.progress = 0,
    this.localPath,
    this.error,
    required this.createdAt,
    this.completedAt,
  });
}

class DownloadManager {
  final AppDatabase _database;
  final ProviderRepository _providerRepository;
  final Map<String, StreamSubscription> _activeDownloads = {};
  
  DownloadManager(this._database, this._providerRepository);
  
  /// Start downloading a song
  Future<void> downloadSong(Song song) async {
    final taskId = 'download_${song.id}_${DateTime.now().millisecondsSinceEpoch}';
    
    // Create download record
    await _database.into(_database.downloads).insert(
      DownloadsCompanion.insert(
        id: taskId,
        songId: song.id,
        providerId: song.providerId ?? 'local',
        status: 'pending',
        progress: const Value(0),
        createdAt: DateTime.now(),
      ),
    );
    
    // Start download
    _startDownload(taskId, song);
  }
  
  Future<void> _startDownload(String taskId, Song song) async {
    try {
      // Update status to downloading
      await _updateDownloadStatus(taskId, DownloadStatus.downloading, progress: 0);
      
      // Get audio stream from provider
      final provider = _providerRepository.providers.firstWhere(
        (p) => p.id == song.providerId,
        orElse: () => throw Exception('Provider not found'),
      );
      
      final stream = await provider.getAudioStream(song.id);
      
      // Get download directory
      final downloadDir = await _getDownloadDirectory();
      final fileName = '${song.id}.${_getFileExtension(song.uri)}';
      final filePath = p.join(downloadDir.path, fileName);
      final file = File(filePath);
      
      // Write stream to file
      final sink = file.openWrite();
      
      await for (final chunk in stream) {
        sink.add(chunk);
        // TODO: Implement progress tracking when content length is available
      }
      
      await sink.close();
      
      // Update status to completed
      await _updateDownloadStatus(
        taskId,
        DownloadStatus.completed,
        progress: 100,
        localPath: filePath,
        completedAt: DateTime.now(),
      );
    } catch (e) {
      await _updateDownloadStatus(
        taskId,
        DownloadStatus.failed,
        error: e.toString(),
      );
    }
  }
  
  Future<void> _updateDownloadStatus(
    String taskId,
    DownloadStatus status, {
    int? progress,
    String? localPath,
    String? error,
    DateTime? completedAt,
  }) async {
    await (_database.update(_database.downloads)
          ..where((d) => d.id.equals(taskId)))
        .write(DownloadsCompanion(
      status: Value(status.name),
      progress: progress != null ? Value(progress) : const Value.absent(),
      localPath: localPath != null ? Value(localPath) : const Value.absent(),
      completedAt: completedAt != null ? Value(completedAt) : const Value.absent(),
    ));
  }
  
  Future<Directory> _getDownloadDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory(p.join(appDir.path, 'downloads'));
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir;
  }
  
  String _getFileExtension(String uri) {
    final ext = p.extension(uri);
    return ext.isNotEmpty ? ext.substring(1) : 'mp3';
  }
  
  /// Get download status for a song
  Future<DownloadStatus?> getDownloadStatus(String songId) async {
    final query = _database.select(_database.downloads)
      ..where((d) => d.songId.equals(songId))
      ..orderBy([(d) => OrderingTerm.desc(d.createdAt)])
      ..limit(1);
    final result = await query.getSingleOrNull();
    return result != null ? DownloadStatus.values.firstWhere(
      (e) => e.name == result.status,
      orElse: () => DownloadStatus.pending,
    ) : null;
  }
  
  /// Cancel download
  Future<void> cancelDownload(String songId) async {
    // TODO: Cancel active stream
    await (_database.update(_database.downloads)
          ..where((d) => d.songId.equals(songId)))
        .write(const DownloadsCompanion(
      status: Value('cancelled'),
    ));
  }
  
  /// Get local path for downloaded song
  Future<String?> getLocalPath(String songId) async {
    final query = _database.select(_database.downloads)
      ..where((d) => d.songId.equals(songId))
      ..where((d) => d.status.equals('completed'))
      ..orderBy([(d) => OrderingTerm.desc(d.createdAt)])
      ..limit(1);
    final result = await query.getSingleOrNull();
    return result?.localPath;
  }
}

final downloadManagerProvider = Provider<DownloadManager>((ref) {
  final database = ref.watch(appDatabaseProvider);
  final repository = ref.watch(providerRepositoryProvider);
  return DownloadManager(database, repository);
});
