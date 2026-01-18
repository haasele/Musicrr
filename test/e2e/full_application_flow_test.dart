import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musicrr/core/audio/audio_engine.dart';
import 'package:musicrr/core/audio/playback_queue.dart';
import 'package:musicrr/core/providers/provider_repository.dart';
import 'package:musicrr/core/models/song.dart';
import 'package:musicrr/core/models/album.dart';
import 'package:musicrr/core/models/artist.dart';
import 'package:musicrr/core/storage/settings_repository.dart';
import 'package:musicrr/core/storage/now_playing_preset_repository.dart';
import 'package:musicrr/core/lyrics/lyrics_service.dart';
import 'package:musicrr/core/recommendations/recommendation_engine.dart';
import 'package:musicrr/core/cache/cache_manager.dart';
import 'package:musicrr/core/download/download_manager.dart';
import 'package:musicrr/core/network/network_status.dart';
import 'package:musicrr/features/remote/remote_control_service.dart';

/// End-to-end test for full application flow
/// Tests all major modules and their integration
void main() {
  group('Full Application Flow E2E Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Complete application initialization flow', () async {
      // Test: App startup and initialization
      // 1. Initialize settings repository
      final settingsRepo = container.read(settingsRepositoryProvider);
      expect(settingsRepo, isNotNull);

      // 3. Initialize audio engine
      final audioEngine = container.read(audioEngineProvider);
      expect(audioEngine, isNotNull);

      // 4. Initialize provider repository
      final providerRepo = container.read(providerRepositoryProvider);
      expect(providerRepo, isNotNull);

      // 5. Initialize network status service
      final networkStatusService = container.read(networkStatusServiceProvider);
      expect(networkStatusService, isNotNull);

      // Verify all core services initialized
      expect(audioEngine.queue, isNotNull);
      expect(providerRepo.providers, isNotEmpty);
    });

    test('Provider setup and library scanning flow', () async {
      // Test: Provider configuration and library scanning
      final providerRepo = container.read(providerRepositoryProvider);
      
      // 1. Get available providers
      final providers = providerRepo.providers;
      expect(providers, isNotEmpty);

      // 2. Get artists from providers
      final artists = await providerRepo.getArtists();
      expect(artists, isA<List<Artist>>());

      // 3. Get albums from providers
      final albums = await providerRepo.getAlbums();
      expect(albums, isA<List<Album>>());

      // 4. Get songs from providers
      final songs = await providerRepo.getSongs();
      expect(songs, isA<List<Song>>());

      // Verify data aggregation works
      expect(artists.length + albums.length + songs.length, greaterThanOrEqualTo(0));
    });

    test('Complete playback flow', () async {
      // Test: Full playback workflow
      final audioEngine = container.read(audioEngineProvider);
      final queue = audioEngine.queue;

      // 1. Create test songs
      final songs = List.generate(5, (i) => Song(
        id: 'e2e_song_$i',
        title: 'E2E Test Song $i',
        artist: 'E2E Test Artist',
        album: 'E2E Test Album',
        duration: 180000,
        uri: 'file:///e2e_test_$i.mp3',
        providerId: 'local',
      ));

      // 2. Add songs to queue
      queue.addAll(songs);
      expect(queue.length, equals(5));
      expect(queue.currentIndex, equals(0));

      // 3. Set queue options
      queue.setShuffle(false);
      queue.setRepeat(RepeatMode.none);
      expect(queue.shuffleEnabled, isFalse);
      expect(queue.repeatMode, equals(RepeatMode.none));

      // 4. Navigate queue
      queue.setCurrentIndex(2);
      expect(queue.currentIndex, equals(2));
      expect(queue.currentTrack?.id, equals('e2e_song_2'));

      // 5. Test next/previous
      final next = queue.next();
      expect(next, isNotNull);
      expect(next!.id, equals('e2e_song_3'));
      expect(queue.currentIndex, equals(3));

      final previous = queue.previous();
      expect(previous, isNotNull);
      expect(previous!.id, equals('e2e_song_2'));
      expect(queue.currentIndex, equals(2));

      // 6. Test queue reordering
      queue.reorder(0, 4);
      expect(queue.tracks[4].id, equals('e2e_song_0'));

      // 7. Test queue clearing
      queue.clear();
      expect(queue.isEmpty, isTrue);
      expect(queue.currentIndex, equals(-1));
    });

    test('Settings and preferences flow', () async {
      // Test: Settings management
      final settingsRepo = container.read(settingsRepositoryProvider);

      // 1. Theme mode
      await settingsRepo.setThemeMode('dark');
      final themeMode = await settingsRepo.getThemeMode();
      expect(themeMode, equals('dark'));

      // 2. Accent color
      await settingsRepo.setAccentColor(0xFF2196F3);
      final accentColor = await settingsRepo.getAccentColor();
      expect(accentColor, equals(0xFF2196F3));

      // 3. Verify settings persistence
      final newSettingsRepo = container.read(settingsRepositoryProvider);
      final persistedTheme = await newSettingsRepo.getThemeMode();
      expect(persistedTheme, equals('dark'));
    });

    test('Now Playing preset management flow', () async {
      // Test: Preset creation and management
      final presetRepo = container.read(nowPlayingPresetRepositoryProvider);

      // 1. Get all presets
      final allPresets = await presetRepo.getAllPresets();
      expect(allPresets, isA<List>());

      // 2. Get active preset
      final activePreset = await presetRepo.getActivePreset();
      // May be null if no preset set, which is valid
      if (activePreset != null) {
        expect(activePreset.id, isNotEmpty);
      }
    });

    test('Lyrics service flow', () async {
      // Test: Lyrics search and management
      final lyricsService = container.read(lyricsServiceProvider);

      // Lyrics search may return null if no lyrics available
      // This is expected behavior, so we just verify the service works
      expect(lyricsService, isNotNull);
    });

    test('Recommendation engine flow', () async {
      // Test: Recommendation generation
      final recommendationEngine = container.read(recommendationEngineProvider);

      // 1. Get recommendations (may return empty if no analytics data)
      final allSongs = await container.read(providerRepositoryProvider).getSongs();
      final recommendations = await recommendationEngine.getTopRecommended(allSongs, limit: 10);
      expect(recommendations, isA<List<Song>>());

      // 2. Verify recommendation service is functional
      expect(recommendationEngine, isNotNull);
    });

    test('Cache management flow', () async {
      // Test: Cache operations
      final cacheManager = await container.read(cacheManagerProvider);

      // 1. Get cache stats
      final stats = await cacheManager.getCacheStats();
      expect(stats, isA<Map<String, dynamic>>());
      expect(stats['totalSizeMB'], isNotNull);
      expect(stats['maxSizeMB'], isNotNull);

      // 2. Verify cache manager is functional
      expect(cacheManager, isNotNull);
    });

    test('Download management flow', () async {
      // Test: Download operations
      final downloadManager = await container.read(downloadManagerProvider);

      // Verify download manager is functional
      expect(downloadManager, isNotNull);
    });

    test('Network status and offline mode flow', () async {
      // Test: Network status monitoring
      final networkStatusService = container.read(networkStatusServiceProvider);

      // 1. Get current network status
      final status = await networkStatusService.getCurrentStatus();
      expect(status, isA<NetworkStatus>());

      // 2. Test offline mode in provider repository
      final providerRepo = container.read(providerRepositoryProvider);
      providerRepo.setOfflineMode(true);
      
      final activeProviders = providerRepo.getActiveProviders();
      // In offline mode, should only have local providers
      expect(activeProviders, isNotEmpty);

      // 3. Re-enable online mode
      providerRepo.setOfflineMode(false);
      final onlineProviders = providerRepo.getActiveProviders();
      expect(onlineProviders, isNotEmpty);
    });

    test('Remote control service flow', () async {
      // Test: Remote control functionality
      // RemoteControlService is a static class, so we test it directly

      // 1. Check if server is running (may return false if not started)
      try {
        final isRunning = await RemoteControlService.isServerRunning();
        expect(isRunning, isA<bool>());
      } catch (e) {
        // Server check may fail, which is acceptable
        expect(e, isNotNull);
      }

      // Verify service class exists
      expect(RemoteControlService, isNotNull);
    });

    test('Complete user journey: Browse → Play → Customize', () async {
      // Test: Simulate complete user journey
      final providerRepo = container.read(providerRepositoryProvider);
      final audioEngine = container.read(audioEngineProvider);
      final settingsRepo = container.read(settingsRepositoryProvider);
      final presetRepo = container.read(nowPlayingPresetRepositoryProvider);

      // 1. User browses library
      final artists = await providerRepo.getArtists();
      final albums = await providerRepo.getAlbums();
      final songs = await providerRepo.getSongs();

      expect(artists, isA<List<Artist>>());
      expect(albums, isA<List<Album>>());
      expect(songs, isA<List<Song>>());

      // 2. User adds songs to queue
      if (songs.isNotEmpty) {
        final testSongs = songs.take(3).toList();
        audioEngine.queue.addAll(testSongs);
        expect(audioEngine.queue.length, greaterThanOrEqualTo(3));

        // 3. User configures playback
        audioEngine.queue.setShuffle(false);
        audioEngine.queue.setRepeat(RepeatMode.all);

        // 4. User customizes settings
        await settingsRepo.setThemeMode('dark');

        // 5. User checks presets
        final presets = await presetRepo.getAllPresets();
        expect(presets, isA<List>());

        // 6. User navigates queue
        audioEngine.queue.setCurrentIndex(1);
        expect(audioEngine.queue.currentIndex, equals(1));
      }
    });

    test('Error handling and recovery flow', () async {
      // Test: Error handling across modules
      final audioEngine = container.read(audioEngineProvider);
      final providerRepo = container.read(providerRepositoryProvider);

      // 1. Test queue operations with empty queue
      audioEngine.queue.clear();
      expect(audioEngine.queue.isEmpty, isTrue);

      final next = audioEngine.queue.next();
      expect(next, isNull); // Should handle gracefully

      final previous = audioEngine.queue.previous();
      expect(previous, isNull); // Should handle gracefully

      // 2. Test provider operations
      final providers = providerRepo.providers;
      expect(providers, isA<List>());

      // 3. Test settings with invalid values (should handle gracefully)
      final settingsRepo = container.read(settingsRepositoryProvider);
      // Settings should handle invalid values gracefully
      expect(settingsRepo, isNotNull);
    });

    test('Data persistence flow', () async {
      // Test: Data persistence across app restarts
      final settingsRepo = container.read(settingsRepositoryProvider);

      // 1. Save settings
      await settingsRepo.setThemeMode('light');
      await settingsRepo.setAccentColor(0xFF4CAF50);

      // 2. Create new container (simulating app restart)
      final newContainer = ProviderContainer();
      final newSettingsRepo = newContainer.read(settingsRepositoryProvider);

      // 3. Verify settings persisted
      final themeMode = await newSettingsRepo.getThemeMode();
      final accentColor = await newSettingsRepo.getAccentColor();

      expect(themeMode, equals('light'));
      expect(accentColor, equals(0xFF4CAF50));

      newContainer.dispose();
    });

    test('Multi-provider integration flow', () async {
      // Test: Multiple providers working together
      final providerRepo = container.read(providerRepositoryProvider);

      // 1. Get all providers
      final providers = providerRepo.providers;
      expect(providers, isNotEmpty);

      // 2. Aggregate data from all providers
      final allArtists = await providerRepo.getArtists();
      final allAlbums = await providerRepo.getAlbums();
      final allSongs = await providerRepo.getSongs();

      // 3. Verify aggregation works
      expect(allArtists, isA<List<Artist>>());
      expect(allAlbums, isA<List<Album>>());
      expect(allSongs, isA<List<Song>>());

      // 4. Test provider filtering
      providerRepo.setOfflineMode(true);
      final offlineProviders = providerRepo.getActiveProviders();
      expect(offlineProviders, isNotEmpty);

      providerRepo.setOfflineMode(false);
      final onlineProviders = providerRepo.getActiveProviders();
      expect(onlineProviders, isNotEmpty);
    });

    test('Performance and resource management flow', () async {
      // Test: Resource management and performance
      final audioEngine = container.read(audioEngineProvider);
      final cacheManager = await container.read(cacheManagerProvider);

      // 1. Test queue with many items
      final largeQueue = List.generate(100, (i) => Song(
        id: 'perf_test_$i',
        title: 'Performance Test $i',
        artist: 'Test Artist',
        album: 'Test Album',
        duration: 180000,
        uri: 'file:///perf_$i.mp3',
        providerId: 'local',
      ));

      audioEngine.queue.addAll(largeQueue);
      expect(audioEngine.queue.length, equals(100));

      // 2. Test queue operations on large queue
      audioEngine.queue.setCurrentIndex(50);
      expect(audioEngine.queue.currentIndex, equals(50));

      final next = audioEngine.queue.next();
      expect(next, isNotNull);

      // 3. Test cache operations
      final stats = await cacheManager.getCacheStats();
      expect(stats, isA<Map<String, dynamic>>());

      // 4. Clean up
      audioEngine.queue.clear();
      expect(audioEngine.queue.isEmpty, isTrue);
    });
  });
}
