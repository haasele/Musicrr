import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:xml/xml.dart' as xml;
import 'media_provider.dart';
import '../models/artist.dart';
import '../models/album.dart';
import '../models/song.dart';
import '../models/playlist.dart';

class WebDAVProvider implements MediaProvider {
  final String _id;
  final String _name;
  final String _baseUrl;
  final String? _username;
  final String? _password;
  bool _isEnabled = true;
  
  late Dio _dio;
  
  WebDAVProvider({
    required String id,
    required String name,
    required String baseUrl,
    String? username,
    String? password,
  }) : _id = id, 
      _name = name, 
      _username = username, 
      _password = password,
      _baseUrl = baseUrl.endsWith('/') 
      ? baseUrl.substring(0, baseUrl.length - 1) 
      : baseUrl;
  
  @override
  String get id => _id;
  
  @override
  String get name => _name;
  
  @override
  bool get isEnabled => _isEnabled;
  
  @override
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  @override
  Future<void> initialize() async {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ));
    
    if (_username != null && _password != null) {
      _dio.options.headers['Authorization'] = 'Basic ${base64Encode(utf8.encode('$_username:$_password'))}';
    }
  }
  
  @override
  Future<void> dispose() async {
    _dio.close();
  }
  
  @override
  Future<List<Artist>> getArtists() async {
    final songs = await getSongs();
    final artistMap = <String, List<Song>>{};
    
    for (final song in songs) {
      if (!artistMap.containsKey(song.artist)) {
        artistMap[song.artist] = [];
      }
      artistMap[song.artist]!.add(song);
    }
    
    return artistMap.entries.map((entry) {
      final albums = entry.value.map((s) => s.album).toSet();
      return Artist(
        id: 'webdav_artist_${entry.key.hashCode}',
        name: entry.key,
        trackCount: entry.value.length,
        albumCount: albums.length,
        providerId: id,
      );
    }).toList();
  }
  
  @override
  Future<List<Album>> getAlbums() async {
    final songs = await getSongs();
    final albumMap = <String, List<Song>>{};
    
    for (final song in songs) {
      final key = '${song.artist}::${song.album}';
      if (!albumMap.containsKey(key)) {
        albumMap[key] = [];
      }
      albumMap[key]!.add(song);
    }
    
    return albumMap.entries.map((entry) {
      final songs = entry.value;
      final firstSong = songs.first;
      return Album(
        id: 'webdav_album_${entry.key.hashCode}',
        title: firstSong.album,
        artist: firstSong.artist,
        trackCount: songs.length,
        providerId: id,
      );
    }).toList();
  }
  
  @override
  Future<List<Song>> getSongs() async {
    final songs = <Song>[];
    await _scanDirectory(_baseUrl, songs);
    return songs;
  }
  
  Future<void> _scanDirectory(String url, List<Song> songs) async {
    try {
      final response = await _dio.request(
        url,
        options: Options(
          method: 'PROPFIND',
          headers: {
            'Depth': '1',
            'Content-Type': 'application/xml',
          },
        ),
        data: '''<?xml version="1.0" encoding="utf-8"?>
<propfind xmlns="DAV:">
  <prop>
    <resourcetype/>
    <getcontenttype/>
    <getcontentlength/>
    <displayname/>
  </prop>
</propfind>''',
      );
      
      if (response.statusCode == 207) {
        // Parse multistatus response
        final document = xml.XmlDocument.parse(response.data as String);
        final responses = document.findAllElements('response');
        
        for (final response in responses) {
          final href = response.findElements('href').first.text;
          final resourcetype = response.findElements('resourcetype').first;
          final contentType = response.findElements('getcontenttype').firstOrNull?.text;
          
          // Skip current directory
          if (href == url || href == '$url/') continue;
          
          if (resourcetype.findElements('collection').isNotEmpty) {
            // Directory - recurse
            await _scanDirectory(href, songs);
          } else if (_isAudioFile(contentType, href)) {
            // Audio file
            final song = await _createSongFromUrl(href);
            if (song != null) {
              songs.add(song);
            }
          }
        }
      }
    } catch (e) {
      // Handle error
    }
  }
  
  bool _isAudioFile(String? contentType, String href) {
    final audioTypes = [
      'audio/mpeg',
      'audio/mp4',
      'audio/flac',
      'audio/wav',
      'audio/ogg',
      'audio/opus',
    ];
    
    if (contentType != null && audioTypes.contains(contentType)) {
      return true;
    }
    
    final ext = href.toLowerCase();
    return ext.endsWith('.mp3') ||
        ext.endsWith('.m4a') ||
        ext.endsWith('.flac') ||
        ext.endsWith('.wav') ||
        ext.endsWith('.opus') ||
        ext.endsWith('.ogg');
  }
  
  Future<Song?> _createSongFromUrl(String url) async {
    try {
      // Extract filename
      final parts = url.split('/');
      final filename = parts.last;
      final nameWithoutExt = filename.split('.').first;
      
      // Basic parsing - in production, would use metadata extractor
      final parts2 = nameWithoutExt.split(' - ');
      final title = parts2.length > 1 ? parts2[1] : nameWithoutExt;
      final artist = parts2.length > 1 ? parts2[0] : 'Unknown Artist';
      
      return Song(
        id: 'webdav_${url.hashCode}',
        title: title,
        artist: artist,
        album: 'Unknown Album',
        duration: 0,
        uri: url,
        providerId: id,
      );
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<List<Playlist>> getPlaylists() async {
    // WebDAV playlists would be stored as M3U files
    // For now, return empty list
    return [];
  }
  
  @override
  Future<Stream<List<int>>> getAudioStream(String songId) async {
    // Extract URL from song ID
    final url = songId.replaceFirst('webdav_', '');
    final response = await _dio.get(
      url,
      options: Options(responseType: ResponseType.stream),
    );
    return response.data.stream;
  }
  
  @override
  Future<String?> getCoverArtUrl(String albumId) async {
    // WebDAV cover art would be in album folder
    // For now, return null
    return null;
  }
  
  // Helper methods for serialization
  String get baseUrl => _baseUrl;
  String? get username => _username;
  String? get password => _password;
}
