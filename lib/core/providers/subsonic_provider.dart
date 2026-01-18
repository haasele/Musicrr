import 'dart:async';
import 'package:dio/dio.dart';
import 'media_provider.dart';
import '../models/artist.dart';
import '../models/album.dart';
import '../models/song.dart';
import '../models/playlist.dart';

class SubsonicProvider implements MediaProvider {
  final String _id;
  final String _name;
  final String _baseUrl;
  final String _username;
  final String _password;
  bool _isEnabled = true;
  
  late Dio _dio;
  String? _token;
  
  SubsonicProvider({
    required String id,
    required String name,
    required String baseUrl,
    required String username,
    required String password,
  }) : _id = id, _name = name, _baseUrl = baseUrl.endsWith('/') 
      ? baseUrl.substring(0, baseUrl.length - 1) 
      : baseUrl,
      _username = username, _password = password;
  
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
    
    // Generate auth token (Subsonic uses MD5 hash of password + salt)
    await _authenticate();
  }
  
  Future<void> _authenticate() async {
    try {
      // Subsonic ping to verify credentials
      final response = await _dio.get('/rest/ping.view', queryParameters: {
        'u': _username,
        'p': _password,
        'v': '1.16.0',
        'c': 'Musicrr',
      });
      
      if (response.statusCode == 200) {
        // Authentication successful
        // Generate token for future requests
        _token = _generateToken();
      }
    } catch (e) {
      // Authentication failed
      throw Exception('Subsonic authentication failed: $e');
    }
  }
  
  String _generateToken() {
    // Subsonic token generation (simplified)
    // In production, use proper MD5 hashing
    return '${_username}_${_password.hashCode}';
  }
  
  Map<String, dynamic> _getAuthParams() {
    return {
      'u': _username,
      't': _token ?? _password,
      's': '', // Salt (optional)
      'v': '1.16.0',
      'c': 'Musicrr',
    };
  }
  
  @override
  Future<void> dispose() async {
    _dio.close();
  }
  
  @override
  Future<List<Artist>> getArtists() async {
    try {
      final response = await _dio.get('/rest/getArtists.view', queryParameters: _getAuthParams());
      
      if (response.statusCode == 200) {
        // Parse XML response
        final artists = <Artist>[];
        // TODO: Parse Subsonic XML response
        return artists;
      }
    } catch (e) {
      // Handle error
    }
    return [];
  }
  
  @override
  Future<List<Album>> getAlbums() async {
    try {
      final response = await _dio.get('/rest/getAlbumList2.view', queryParameters: {
        ..._getAuthParams(),
        'type': 'alphabeticalByName',
        'size': 500,
      });
      
      if (response.statusCode == 200) {
        // Parse XML response
        final albums = <Album>[];
        // TODO: Parse Subsonic XML response
        return albums;
      }
    } catch (e) {
      // Handle error
    }
    return [];
  }
  
  @override
  Future<List<Song>> getSongs({String? albumId}) async {
    try {
      String endpoint;
      Map<String, dynamic> params = _getAuthParams();
      
      if (albumId != null) {
        endpoint = '/rest/getAlbum.view';
        params['id'] = albumId;
      } else {
        endpoint = '/rest/getSongsByGenre.view';
        params['count'] = 500;
      }
      
      final response = await _dio.get(endpoint, queryParameters: params);
      
      if (response.statusCode == 200) {
        // Parse XML response
        final songs = <Song>[];
        // TODO: Parse Subsonic XML response
        return songs;
      }
    } catch (e) {
      // Handle error
    }
    return [];
  }
  
  @override
  Future<List<Playlist>> getPlaylists() async {
    try {
      final response = await _dio.get('/rest/getPlaylists.view', queryParameters: _getAuthParams());
      
      if (response.statusCode == 200) {
        // Parse XML response
        final playlists = <Playlist>[];
        // TODO: Parse Subsonic XML response
        return playlists;
      }
    } catch (e) {
      // Handle error
    }
    return [];
  }
  
  @override
  Future<Stream<List<int>>> getAudioStream(String songId) async {
    try {
      final response = await _dio.get(
        '/rest/stream.view',
        queryParameters: {
          ..._getAuthParams(),
          'id': songId,
        },
        options: Options(responseType: ResponseType.stream),
      );
      return response.data.stream;
    } catch (e) {
      throw Exception('Failed to stream audio: $e');
    }
  }
  
  @override
  Future<String?> getCoverArtUrl(String albumId) async {
    return '$_baseUrl/rest/getCoverArt.view?${Uri(queryParameters: {
      ..._getAuthParams(),
      'id': albumId,
    }).query}';
  }
  
  // Helper methods for serialization
  String get baseUrl => _baseUrl;
  String get username => _username;
  String get password => _password;
}
