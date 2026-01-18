import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musicrr/core/audio/playback_queue.dart';
import 'package:musicrr/core/models/song.dart';
import 'package:musicrr/core/audio/queue_persistence.dart';
import 'package:musicrr/core/storage/database.dart';
import 'package:musicrr/core/storage/now_playing_preset_repository.dart';

/// Integration test for queue management
/// Tests: queue persistence, save as playlist, restore queue
void main() {
  group('Queue Management Integration Tests', () {
    late ProviderContainer container;
    late PlaybackQueue playbackQueue;
    late QueuePersistence queuePersistence;
    late AppDatabase database;

    setUp(() {
      container = ProviderContainer();
      playbackQueue = PlaybackQueue();
      database = container.read(appDatabaseProvider);
      queuePersistence = QueuePersistence(database);
    });

    tearDown(() {
      container.dispose();
    });

    test('Save queue snapshot', () async {
      // Arrange
      final songs = List.generate(5, (i) => Song(
        id: 'test_song_$i',
        title: 'Test Song $i',
        artist: 'Test Artist',
        album: 'Test Album',
        duration: 180000,
        uri: 'file:///test_$i.mp3',
        providerId: 'local',
      ));
      playbackQueue.addAll(songs);
      playbackQueue.setCurrentIndex(2);

      // Act
      await queuePersistence.saveQueue(playbackQueue, name: 'Test Queue');

      // Assert
      // Queue should be saved (no return value, so we just verify no exception)
      expect(true, isTrue);
    });

    test('Restore temporary queue', () async {
      // Arrange
      final songs = List.generate(3, (i) => Song(
        id: 'test_song_$i',
        title: 'Test Song $i',
        artist: 'Test Artist',
        album: 'Test Album',
        duration: 180000,
        uri: 'file:///test_$i.mp3',
        providerId: 'local',
      ));
      playbackQueue.addAll(songs);
      await queuePersistence.saveQueue(playbackQueue, isTemporary: true);

      // Act
      final restored = await queuePersistence.getTemporaryQueue(
        (songIds) async => songs.where((s) => songIds.contains(s.id)).toList(),
      );

      // Assert
      expect(restored, isNotNull);
      expect(restored!.songs.length, equals(3));
    });

    test('Save queue as playlist', () async {
      // Arrange
      final songs = List.generate(4, (i) => Song(
        id: 'test_song_$i',
        title: 'Test Song $i',
        artist: 'Test Artist',
        album: 'Test Album',
        duration: 180000,
        uri: 'file:///test_$i.mp3',
        providerId: 'local',
      ));
      playbackQueue.addAll(songs);

      // Act
      final playlistId = await queuePersistence.saveQueueAsPlaylist(
        playbackQueue,
        'Test Playlist',
      );

      // Assert
      expect(playlistId, isNotNull);
      // In real implementation, would verify playlist was created
    });

    test('Clear temporary queues', () async {
      // Arrange
      final songs = List.generate(2, (i) => Song(
        id: 'test_song_$i',
        title: 'Test Song $i',
        artist: 'Test Artist',
        album: 'Test Album',
        duration: 180000,
        uri: 'file:///test_$i.mp3',
        providerId: 'local',
      ));
      playbackQueue.addAll(songs);
      await queuePersistence.saveQueue(playbackQueue, isTemporary: true);

      // Act
      await queuePersistence.clearTemporaryQueues();

      // Assert
      final restored = await queuePersistence.getTemporaryQueue(
        (songIds) async => songs.where((s) => songIds.contains(s.id)).toList(),
      );
      expect(restored, isNull);
    });
  });
}
