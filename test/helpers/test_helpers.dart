import 'package:musicrr/core/models/song.dart';
import 'package:musicrr/core/models/album.dart';
import 'package:musicrr/core/models/artist.dart';

/// Test helper functions for creating test data
class TestHelpers {
  /// Create a test song
  static Song createTestSong({
    String? id,
    String? title,
    String? artist,
    String? album,
    int? duration,
    String? providerId,
    String? uri,
  }) {
    return Song(
      id: id ?? 'test_song_${DateTime.now().millisecondsSinceEpoch}',
      title: title ?? 'Test Song',
      artist: artist ?? 'Test Artist',
      album: album ?? 'Test Album',
      duration: duration ?? 180000,
      uri: uri ?? 'file:///test.mp3',
      providerId: providerId ?? 'local',
    );
  }

  /// Create a test album
  static Album createTestAlbum({
    String? id,
    String? title,
    String? artist,
    int? year,
    String? providerId,
  }) {
    return Album(
      id: id ?? 'test_album_${DateTime.now().millisecondsSinceEpoch}',
      title: title ?? 'Test Album',
      artist: artist ?? 'Test Artist',
      year: year,
      providerId: providerId ?? 'local',
    );
  }

  /// Create a test artist
  static Artist createTestArtist({
    String? id,
    String? name,
    String? providerId,
  }) {
    return Artist(
      id: id ?? 'test_artist_${DateTime.now().millisecondsSinceEpoch}',
      name: name ?? 'Test Artist',
      providerId: providerId ?? 'local',
    );
  }

  /// Create multiple test songs
  static List<Song> createTestSongs(int count, {String? artist, String? album}) {
    return List.generate(count, (i) => createTestSong(
      title: 'Test Song $i',
      artist: artist ?? 'Test Artist',
      album: album ?? 'Test Album',
    ));
  }
}
