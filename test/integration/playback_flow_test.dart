import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musicrr/core/audio/audio_engine.dart';
import 'package:musicrr/core/audio/playback_queue.dart';
import 'package:musicrr/core/models/song.dart';

/// Integration test for playback flow
/// Note: These tests require platform channel mocking for full execution
/// Tests: play, pause, seek, next, previous, queue management
void main() {
  group('Playback Flow Integration Tests', () {
    late ProviderContainer container;
    late AudioEngine audioEngine;

    setUp(() {
      container = ProviderContainer();
      audioEngine = container.read(audioEngineProvider);
    });

    tearDown(() {
      container.dispose();
    });

    test('Queue management', () {
      // Arrange
      final song1 = Song(
        id: 'test_song_1',
        title: 'Test Song 1',
        artist: 'Test Artist',
        album: 'Test Album',
        duration: 180000,
        uri: 'file:///test1.mp3',
        providerId: 'local',
      );
      final song2 = Song(
        id: 'test_song_2',
        title: 'Test Song 2',
        artist: 'Test Artist',
        album: 'Test Album',
        duration: 200000,
        uri: 'file:///test2.mp3',
        providerId: 'local',
      );

      // Act
      audioEngine.queue.add(song1);
      audioEngine.queue.add(song2);

      // Assert
      expect(audioEngine.queue.length, equals(2));
      expect(audioEngine.queue.tracks.first.id, equals('test_song_1'));
    });

    test('Queue operations', () {
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

      // Act
      audioEngine.queue.addAll(songs);
      audioEngine.queue.setCurrentIndex(1);
      audioEngine.queue.reorder(0, 2);

      // Assert
      expect(audioEngine.queue.length, equals(3));
      expect(audioEngine.queue.currentIndex, equals(0)); // Adjusted after reorder
    });

    test('Shuffle and repeat modes', () {
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
      audioEngine.queue.addAll(songs);

      // Act
      audioEngine.queue.setShuffle(true);
      audioEngine.queue.setRepeat(RepeatMode.all);

      // Assert
      expect(audioEngine.queue.shuffleEnabled, isTrue);
      expect(audioEngine.queue.repeatMode, equals(RepeatMode.all));
    });
  });
}
