import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../storage/database.dart';
import '../storage/provider_settings_repository.dart';
import '../storage/now_playing_preset_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service for exporting user data for privacy compliance
class DataExportService {
  final AppDatabase _database;
  final ProviderSettingsRepository _providerSettingsRepo;

  DataExportService(
    this._database,
    this._providerSettingsRepo,
  );

  /// Export all user data to a JSON file
  Future<String> exportAllData() async {
    final exportData = <String, dynamic>{
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0',
      'data': <String, dynamic>{},
    };

    // Export playback analytics
    final analytics = await _exportAnalytics();
    exportData['data']['playbackAnalytics'] = analytics;

    // Export lyrics
    final lyrics = await _exportLyrics();
    exportData['data']['lyrics'] = lyrics;

    // Export now playing presets
    final presets = await _exportPresets();
    exportData['data']['nowPlayingPresets'] = presets;

    // Export queue snapshots
    final queues = await _exportQueueSnapshots();
    exportData['data']['queueSnapshots'] = queues;

    // Export downloads
    final downloads = await _exportDownloads();
    exportData['data']['downloads'] = downloads;

    // Export cache metadata
    final cache = await _exportCacheMetadata();
    exportData['data']['cacheMetadata'] = cache;

    // Export settings
    final settings = await _exportSettings();
    exportData['data']['settings'] = settings;

    // Export provider settings
    final providerSettings = await _exportProviderSettings();
    exportData['data']['providerSettings'] = providerSettings;

    // Write to file
    final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
    final exportDir = await getApplicationDocumentsDirectory();
    final exportFile = File(p.join(exportDir.path, 'musicrr_data_export_${DateTime.now().millisecondsSinceEpoch}.json'));
    await exportFile.writeAsString(jsonString);

    return exportFile.path;
  }

  Future<List<Map<String, dynamic>>> _exportAnalytics() async {
    final analytics = await _database.select(_database.playbackAnalytics).get();
    return analytics.map((a) => {
      'id': a.id,
      'songId': a.songId,
      'playedAt': a.playedAt.toIso8601String(),
      'durationMs': a.durationMs,
      'completed': a.completed,
      'skipped': a.skipped,
      'skipPositionMs': a.skipPositionMs,
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _exportLyrics() async {
    final lyrics = await _database.select(_database.lyricsTable).get();
    return lyrics.map((l) => {
      'id': l.id,
      'songId': l.songId,
      'lyricsText': l.lyricsText,
      'lrcTimestampsJson': l.lrcTimestampsJson,
      'isSynced': l.isSynced,
      'source': l.source,
      'createdAt': l.createdAt.toIso8601String(),
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _exportPresets() async {
    final presets = await _database.select(_database.nowPlayingPresets).get();
    return presets.map((p) => {
      'id': p.id,
      'name': p.name,
      'description': p.description,
      'layoutJson': p.layoutJson,
      'backgroundConfigJson': p.backgroundConfigJson,
      'scope': p.scope,
      'sourceId': p.sourceId,
      'createdAt': p.createdAt.toIso8601String(),
      'lastModified': p.lastModified?.toIso8601String(),
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _exportQueueSnapshots() async {
    final queues = await _database.select(_database.queueSnapshots).get();
    return queues.map((q) => {
      'id': q.id,
      'name': q.name,
      'queueJson': q.queueJson,
      'currentIndex': q.currentIndex,
      'shuffleEnabled': q.shuffleEnabled,
      'repeatMode': q.repeatMode,
      'createdAt': q.createdAt.toIso8601String(),
      'isTemporary': q.isTemporary,
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _exportDownloads() async {
    final downloads = await _database.select(_database.downloads).get();
    return downloads.map((d) => {
      'id': d.id,
      'songId': d.songId,
      'providerId': d.providerId,
      'status': d.status,
      'progress': d.progress,
      'localPath': d.localPath,
      'createdAt': d.createdAt.toIso8601String(),
      'completedAt': d.completedAt?.toIso8601String(),
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _exportCacheMetadata() async {
    final cache = await _database.select(_database.cacheMetadata).get();
    return cache.map((c) => {
      'id': c.id,
      'songId': c.songId,
      'providerId': c.providerId,
      'cachePath': c.cachePath,
      'fileSizeBytes': c.fileSizeBytes,
      'cachedAt': c.cachedAt.toIso8601String(),
      'lastAccessed': c.lastAccessed.toIso8601String(),
      'accessCount': c.accessCount,
      'priority': c.priority,
    }).toList();
  }

  Future<Map<String, dynamic>> _exportSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'themeMode': prefs.getString('theme_mode'),
      'accentColor': prefs.getInt('accent_color'),
      'offlineMode': prefs.getBool('offline_mode'),
    };
  }

  Future<List<Map<String, dynamic>>> _exportProviderSettings() async {
    // Get all provider IDs from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith('provider_settings_'));
    final providerIds = keys.map((key) => key.replaceFirst('provider_settings_', '').split('_').first).toSet();

    final settings = <Map<String, dynamic>>[];
    for (final providerId in providerIds) {
      final setting = await _providerSettingsRepo.getSettings(providerId);
      settings.add(setting.toJson());
    }

    return settings;
  }

  /// Delete all user data (GDPR right to be forgotten)
  Future<void> deleteAllData() async {
    // Delete analytics
    await (_database.delete(_database.playbackAnalytics)).go();

    // Delete lyrics
    await (_database.delete(_database.lyricsTable)).go();

    // Delete presets
    await (_database.delete(_database.nowPlayingPresets)).go();

    // Delete queue snapshots
    await (_database.delete(_database.queueSnapshots)).go();

    // Delete downloads metadata (files are kept)
    await (_database.delete(_database.downloads)).go();

    // Delete cache metadata (files are kept)
    await (_database.delete(_database.cacheMetadata)).go();

    // Clear settings
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

final dataExportServiceProvider = Provider<Future<DataExportService>>((ref) async {
  final database = ref.watch(appDatabaseProvider);
  final providerSettingsRepo = ref.watch(providerSettingsRepositoryProvider);
  return DataExportService(database, providerSettingsRepo);
});
