import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/database.dart';
import '../storage/now_playing_preset_repository.dart';

class CacheManager {
  final AppDatabase _database;
  final int _maxCacheSizeBytes; // Default: 1GB
  final Directory _cacheDirectory;
  
  CacheManager(this._database, this._maxCacheSizeBytes, this._cacheDirectory);
  
  /// Get cache directory
  static Future<Directory> getCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    return Directory(p.join(appDir.path, 'cache'));
  }
  
  /// Cache a file
  Future<String> cacheFile(String songId, String providerId, Stream<List<int>> stream) async {
    final fileName = '${songId}_$providerId}';
    final filePath = p.join(_cacheDirectory.path, fileName);
    final file = File(filePath);
    
    // Write stream to file
    final sink = file.openWrite();
    await for (final chunk in stream) {
      sink.add(chunk);
    }
    await sink.close();
    
    final fileSize = await file.length();
    
    // Record in database
    await _database.into(_database.cacheMetadata).insertOnConflictUpdate(
      CacheMetadataCompanion.insert(
        id: 'cache_${songId}_$providerId}',
        songId: songId,
        providerId: providerId,
        cachePath: filePath,
        fileSizeBytes: fileSize.toInt(),
        cachedAt: DateTime.now(),
        lastAccessed: DateTime.now(),
        accessCount: const Value(1),
        priority: const Value(0),
      ),
    );
    
    // Check cache size and cleanup if needed
    await _enforceCacheSize();
    
    return filePath;
  }
  
  /// Get cached file path
  Future<String?> getCachedPath(String songId, String providerId) async {
    final query = _database.select(_database.cacheMetadata)
      ..where((c) => c.songId.equals(songId))
      ..where((c) => c.providerId.equals(providerId));
    final result = await query.getSingleOrNull();
    
    if (result != null) {
      final file = File(result.cachePath);
      if (await file.exists()) {
        // Update access metadata
        await (_database.update(_database.cacheMetadata)
              ..where((c) => c.id.equals(result.id)))
            .write(CacheMetadataCompanion(
          lastAccessed: Value(DateTime.now()),
          accessCount: Value(result.accessCount + 1),
        ));
        
        return result.cachePath;
      } else {
        // File doesn't exist, remove from database
        await (_database.delete(_database.cacheMetadata)
              ..where((c) => c.id.equals(result.id)))
            .go();
      }
    }
    
    return null;
  }
  
  /// Enforce cache size limit
  Future<void> _enforceCacheSize() async {
    final totalSize = await _getTotalCacheSize();
    
    if (totalSize > _maxCacheSizeBytes) {
      // Get all cache entries sorted by priority and last accessed
      final allCache = await _database.select(_database.cacheMetadata).get();
      
      // Sort by priority (lower = less important), then by last accessed
      allCache.sort((a, b) {
        final priorityCompare = a.priority.compareTo(b.priority);
        if (priorityCompare != 0) return priorityCompare;
        return a.lastAccessed.compareTo(b.lastAccessed);
      });
      
      // Delete oldest/lowest priority files until under limit
      int currentSize = totalSize;
      for (final entry in allCache) {
        if (currentSize <= _maxCacheSizeBytes) break;
        
        final file = File(entry.cachePath);
        if (await file.exists()) {
          final fileSize = await file.length();
          await file.delete();
          await (_database.delete(_database.cacheMetadata)
                ..where((c) => c.id.equals(entry.id)))
              .go();
          currentSize -= fileSize.toInt();
        }
      }
    }
  }
  
  Future<int> _getTotalCacheSize() async {
    final allCache = await _database.select(_database.cacheMetadata).get();
    int totalSize = 0;
    
    for (final entry in allCache) {
      final file = File(entry.cachePath);
      if (await file.exists()) {
        totalSize += entry.fileSizeBytes;
      }
    }
    
    return totalSize;
  }
  
  /// Clear all cache
  Future<void> clearCache() async {
    final allCache = await _database.select(_database.cacheMetadata).get();
    
    for (final entry in allCache) {
      final file = File(entry.cachePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    
    await (_database.delete(_database.cacheMetadata)).go();
  }
  
  /// Get cache usage statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    final totalSize = await _getTotalCacheSize();
    final allCache = await _database.select(_database.cacheMetadata).get();
    
    return {
      'totalSizeBytes': totalSize,
      'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
      'fileCount': allCache.length,
      'maxSizeBytes': _maxCacheSizeBytes,
      'maxSizeMB': (_maxCacheSizeBytes / (1024 * 1024)).toStringAsFixed(2),
      'usagePercent': ((totalSize / _maxCacheSizeBytes) * 100).toStringAsFixed(1),
    };
  }
}

final cacheManagerProvider = Provider<Future<CacheManager>>((ref) async {
  final database = ref.watch(appDatabaseProvider);
  final cacheDir = await CacheManager.getCacheDirectory();
  if (!await cacheDir.exists()) {
    await cacheDir.create(recursive: true);
  }
  return CacheManager(database, 1024 * 1024 * 1024, cacheDir); // 1GB default
});
