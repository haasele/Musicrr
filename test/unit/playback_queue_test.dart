import 'package:flutter_test/flutter_test.dart';
import 'package:musicrr/core/audio/playback_queue.dart';
import 'package:musicrr/core/models/song.dart';

void main() {
  group('PlaybackQueue Unit Tests', () {
    late PlaybackQueue queue;

    setUp(() {
      queue = PlaybackQueue();
    });

    test('Add song to queue', () {
      // Arrange
      final song = Song(
        id: 'test_song',
        title: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        duration: 180000,
        uri: 'file:///test.mp3',
      );

      // Act
      queue.add(song);

      // Assert
      expect(queue.length, equals(1));
      expect(queue.tracks.first.id, equals('test_song'));
      expect(queue.currentIndex, equals(0));
    });

    test('Add multiple songs', () {
      // Arrange
      final songs = List.generate(5, (i) => Song(
        id: 'song_$i',
        title: 'Song $i',
        artist: 'Artist',
        album: 'Album',
        duration: 180000,
        uri: 'file:///song_$i.mp3',
      ));

      // Act
      queue.addAll(songs);

      // Assert
      expect(queue.length, equals(5));
      expect(queue.currentIndex, equals(0));
    });

    test('Remove song from queue', () {
      // Arrange
      final songs = List.generate(3, (i) => Song(
        id: 'song_$i',
        title: 'Song $i',
        artist: 'Artist',
        album: 'Album',
        duration: 180000,
        uri: 'file:///song_$i.mp3',
      ));
      queue.addAll(songs);
      queue.setCurrentIndex(1);

      // Act
      queue.removeAt(0);

      // Assert
      expect(queue.length, equals(2));
      expect(queue.currentIndex, equals(0)); // Adjusted after removal
    });

    test('Reorder songs in queue', () {
      // Arrange
      final songs = List.generate(5, (i) => Song(
        id: 'song_$i',
        title: 'Song $i',
        artist: 'Artist',
        album: 'Album',
        duration: 180000,
        uri: 'file:///song_$i.mp3',
      ));
      queue.addAll(songs);
      queue.setCurrentIndex(2);

      // Act
      queue.reorder(0, 3);

      // Assert
      expect(queue.tracks[3].id, equals('song_0'));
      expect(queue.currentIndex, equals(1)); // Adjusted after reorder
    });

    test('Next track without repeat', () {
      // Arrange
      final songs = List.generate(3, (i) => Song(
        id: 'song_$i',
        title: 'Song $i',
        artist: 'Artist',
        album: 'Album',
        duration: 180000,
        uri: 'file:///song_$i.mp3',
      ));
      queue.addAll(songs);
      queue.setCurrentIndex(0);

      // Act
      final next = queue.next();

      // Assert
      expect(next, isNotNull);
      expect(next!.id, equals('song_1'));
      expect(queue.currentIndex, equals(1));
    });

    test('Previous track without repeat', () {
      // Arrange
      final songs = List.generate(3, (i) => Song(
        id: 'song_$i',
        title: 'Song $i',
        artist: 'Artist',
        album: 'Album',
        duration: 180000,
        uri: 'file:///song_$i.mp3',
      ));
      queue.addAll(songs);
      queue.setCurrentIndex(2);

      // Act
      final previous = queue.previous();

      // Assert
      expect(previous, isNotNull);
      expect(previous!.id, equals('song_1'));
      expect(queue.currentIndex, equals(1));
    });

    test('Shuffle mode', () {
      // Arrange
      final songs = List.generate(10, (i) => Song(
        id: 'song_$i',
        title: 'Song $i',
        artist: 'Artist',
        album: 'Album',
        duration: 180000,
        uri: 'file:///song_$i.mp3',
      ));
      queue.addAll(songs);

      // Act
      queue.setShuffle(true);

      // Assert
      expect(queue.shuffleEnabled, isTrue);
      // Order should be different (non-deterministic, so just check flag)
    });

    test('Repeat mode', () {
      // Arrange
      final song = Song(
        id: 'test_song',
        title: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        duration: 180000,
        uri: 'file:///test.mp3',
      );
      queue.add(song);

      // Act
      queue.setRepeat(RepeatMode.all);

      // Assert
      expect(queue.repeatMode, equals(RepeatMode.all));
    });

    test('Clear queue', () {
      // Arrange
      final songs = List.generate(5, (i) => Song(
        id: 'song_$i',
        title: 'Song $i',
        artist: 'Artist',
        album: 'Album',
        duration: 180000,
        uri: 'file:///song_$i.mp3',
      ));
      queue.addAll(songs);

      // Act
      queue.clear();

      // Assert
      expect(queue.isEmpty, isTrue);
      expect(queue.currentIndex, equals(-1));
    });
  });
}
