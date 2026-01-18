import 'dart:async';
import '../models/artist.dart';
import '../models/album.dart';
import '../models/song.dart';
import '../models/playlist.dart';

abstract class MediaProvider {
  String get id;
  String get name;
  bool get isEnabled;
  
  void setEnabled(bool enabled);

  Future<List<Artist>> getArtists();
  Future<List<Album>> getAlbums();
  Future<List<Song>> getSongs();
  Future<List<Playlist>> getPlaylists();
  
  Future<Stream<List<int>>> getAudioStream(String songId);
  Future<String?> getCoverArtUrl(String albumId);
  
  Future<void> initialize();
  Future<void> dispose();
}
