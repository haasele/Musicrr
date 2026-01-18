import 'dart:async';
import 'package:dio/dio.dart';
import 'media_provider.dart';
import '../models/artist.dart';
import '../models/album.dart';
import '../models/song.dart';
import '../models/playlist.dart';

class JellyfinProvider implements MediaProvider {
  final String _id;
  final String _name;
  final String _baseUrl;
  final String _username;
  final String _password;
  bool _isEnabled = true;
  
  late Dio _dio;
  String? _accessToken;
  String? _userId;
  
  JellyfinProvider({
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
      headers: {
        'Content-Type': 'application/json',
      },
    ));
    
    await _authenticate();
  }
  
  Future<void> _authenticate() async {
    try {
      // Jellyfin authentication
      final response = await _dio.post(
        '/Users/authenticatebyname',
        data: {
          'Username': _username,
          'Pw': _password,
        },
        options: Options(
          headers: {
            'X-Emby-Authorization': 'MediaBrowser Client="Musicrr", Device="Android", DeviceId="musicrr-device", Version="1.0.0"',
          },
        ),
      );
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        _accessToken = data['AccessToken'] as String?;
        _userId = data['User']['Id'] as String?;
        
        // Set auth header for future requests
        _dio.options.headers['X-Emby-Token'] = _accessToken;
      }
    } catch (e) {
      throw Exception('Jellyfin authentication failed: $e');
    }
  }
  
  @override
  Future<void> dispose() async {
    _dio.close();
  }
  
  @override
  Future<List<Artist>> getArtists() async {
    try {
      final response = await _dio.get('/Artists', queryParameters: {
        'UserId': _userId,
        'Recursive': true,
        'IncludeItemTypes': 'Audio',
      });
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final items = data['Items'] as List<dynamic>? ?? [];
        
        return items.map((item) {
          return Artist(
            id: 'jellyfin_artist_${item['Id']}',
            name: item['Name'] as String,
            albumCount: item['AlbumCount'] as int?,
            trackCount: item['SongCount'] as int?,
            providerId: id,
          );
        }).toList();
      }
    } catch (e) {
      // Handle error
    }
    return [];
  }
  
  @override
  Future<List<Album>> getAlbums({String? artistId}) async {
    try {
      final queryParams = {
        'UserId': _userId,
        'Recursive': true,
        'IncludeItemTypes': 'MusicAlbum',
      };
      
      if (artistId != null) {
        queryParams['ArtistIds'] = artistId;
      }
      
      final response = await _dio.get('/Items', queryParameters: queryParams);
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final items = data['Items'] as List<dynamic>? ?? [];
        
        return items.map((item) {
          return Album(
            id: 'jellyfin_album_${item['Id']}',
            title: item['Name'] as String,
            artist: (item['AlbumArtist'] as String?) ?? 'Unknown Artist',
            trackCount: item['ChildCount'] as int?,
            providerId: id,
          );
        }).toList();
      }
    } catch (e) {
      // Handle error
    }
    return [];
  }
  
  @override
  Future<List<Song>> getSongs({String? albumId, String? artistId}) async {
    try {
      final queryParams = {
        'UserId': _userId,
        'Recursive': true,
        'IncludeItemTypes': 'Audio',
      };
      
      if (albumId != null) {
        queryParams['ParentId'] = albumId;
      }
      
      final response = await _dio.get('/Items', queryParameters: queryParams);
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final items = data['Items'] as List<dynamic>? ?? [];
        
        return items.map((item) {
          return Song(
            id: 'jellyfin_song_${item['Id']}',
            title: item['Name'] as String,
            artist: (item['Artists'] as List<dynamic>?)?.first as String? ?? 'Unknown Artist',
            album: item['Album'] as String? ?? 'Unknown Album',
            duration: (item['RunTimeTicks'] as int?) != null
                ? (item['RunTimeTicks'] as int) ~/ 10000
                : 0,
            uri: '$_baseUrl/Audio/${item['Id']}/stream',
            providerId: id,
          );
        }).toList();
      }
    } catch (e) {
      // Handle error
    }
    return [];
  }
  
  @override
  Future<List<Playlist>> getPlaylists() async {
    try {
      final response = await _dio.get('/Playlists', queryParameters: {
        'UserId': _userId,
      });
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final items = data['Items'] as List<dynamic>? ?? [];
        
        return items.map((item) {
          return Playlist(
            id: 'jellyfin_playlist_${item['Id']}',
            name: item['Name'] as String,
            description: item['Overview'] as String?,
            trackCount: item['ChildCount'] as int?,
            providerId: id,
          );
        }).toList();
      }
    } catch (e) {
      // Handle error
    }
    return [];
  }
  
  @override
  Future<Stream<List<int>>> getAudioStream(String songId) async {
    try {
      // Extract Jellyfin item ID from song ID
      final itemId = songId.replaceFirst('jellyfin_song_', '');
      final response = await _dio.get(
        '/Audio/$itemId/stream',
        options: Options(responseType: ResponseType.stream),
      );
      return response.data.stream;
    } catch (e) {
      throw Exception('Failed to stream audio: $e');
    }
  }
  
  @override
  Future<String?> getCoverArtUrl(String albumId) async {
    final itemId = albumId.replaceFirst('jellyfin_album_', '');
    return '$_baseUrl/Items/$itemId/Images/Primary';
  }
  
  // Helper methods for serialization
  String get baseUrl => _baseUrl;
  String get username => _username;
  String get password => _password;
}
