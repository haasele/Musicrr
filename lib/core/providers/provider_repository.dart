import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'media_provider.dart';
import '../models/artist.dart';
import '../models/album.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import 'local_provider.dart';
import 'webdav_provider.dart';
import 'smb_provider.dart';
import 'subsonic_provider.dart';
import 'jellyfin_provider.dart';

class ProviderRepository {
  final List<MediaProvider> _providers = [];
  bool _offlineMode = false;
  static const String _providersKey = 'saved_providers';

  ProviderRepository() {
    // Initialize with LocalProvider by default
    _providers.add(LocalProvider());
    _loadProviders();
  }
  
  Future<void> _loadProviders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final providersJson = prefs.getStringList(_providersKey);
      if (providersJson == null || providersJson.isEmpty) return;
      
      for (final jsonStr in providersJson) {
        try {
          final data = jsonDecode(jsonStr) as Map<String, dynamic>;
          final type = data['type'] as String;
          final provider = _createProviderFromJson(type, data);
          if (provider != null && !_providers.any((p) => p.id == provider.id)) {
            _providers.add(provider);
            await provider.initialize();
          }
        } catch (e) {
          // Skip invalid provider data
        }
      }
    } catch (e) {
      // Handle error
    }
  }
  
  MediaProvider? _createProviderFromJson(String type, Map<String, dynamic> data) {
    try {
      switch (type) {
        case 'webdav':
          return WebDAVProvider(
            id: data['id'] as String,
            name: data['name'] as String,
            baseUrl: data['baseUrl'] as String,
            username: data['username'] as String?,
            password: data['password'] as String?,
          );
        case 'smb':
          return SMBProvider(
            id: data['id'] as String,
            name: data['name'] as String,
            server: data['server'] as String,
            share: data['share'] as String,
            username: data['username'] as String?,
            password: data['password'] as String?,
            workgroup: data['workgroup'] as String?,
          );
        case 'subsonic':
          return SubsonicProvider(
            id: data['id'] as String,
            name: data['name'] as String,
            baseUrl: data['baseUrl'] as String,
            username: data['username'] as String,
            password: data['password'] as String,
          );
        case 'jellyfin':
          return JellyfinProvider(
            id: data['id'] as String,
            name: data['name'] as String,
            baseUrl: data['baseUrl'] as String,
            username: data['username'] as String,
            password: data['password'] as String,
          );
        default:
          return null;
      }
    } catch (e) {
      return null;
    }
  }
  
  Map<String, dynamic> _providerToJson(MediaProvider provider) {
    if (provider is WebDAVProvider) {
      return {
        'type': 'webdav',
        'id': provider.id,
        'name': provider.name,
        'baseUrl': provider.baseUrl,
        'username': provider.username,
        'password': provider.password,
      };
    } else if (provider is SMBProvider) {
      return {
        'type': 'smb',
        'id': provider.id,
        'name': provider.name,
        'server': provider.server,
        'share': provider.share,
        'username': provider.username,
        'password': provider.password,
        'workgroup': provider.workgroup,
      };
    } else if (provider is SubsonicProvider) {
      return {
        'type': 'subsonic',
        'id': provider.id,
        'name': provider.name,
        'baseUrl': provider.baseUrl,
        'username': provider.username,
        'password': provider.password,
      };
    } else if (provider is JellyfinProvider) {
      return {
        'type': 'jellyfin',
        'id': provider.id,
        'name': provider.name,
        'baseUrl': provider.baseUrl,
        'username': provider.username,
        'password': provider.password,
      };
    }
    return {};
  }
  
  Future<void> _saveProviders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final providersJson = _providers
          .where((p) => p.runtimeType != LocalProvider)
          .map((p) => jsonEncode(_providerToJson(p)))
          .toList();
      await prefs.setStringList(_providersKey, providersJson);
    } catch (e) {
      // Handle error
    }
  }

  List<MediaProvider> get providers => List.unmodifiable(_providers);
  bool get offlineMode => _offlineMode;

  Future<void> addProvider(MediaProvider provider) async {
    if (!_providers.any((p) => p.id == provider.id)) {
      _providers.add(provider);
      await provider.initialize();
      await _saveProviders();
    }
  }

  Future<void> removeProvider(String providerId) async {
    final provider = _providers.firstWhere(
      (p) => p.id == providerId,
      orElse: () => throw Exception('Provider not found'),
    );
    provider.dispose();
    _providers.remove(provider);
    await _saveProviders();
  }
  
  Future<void> setProviderEnabled(String providerId, bool enabled) async {
    final provider = _providers.firstWhere(
      (p) => p.id == providerId,
      orElse: () => throw Exception('Provider not found'),
    );
    provider.setEnabled(enabled);
    await _saveProviders();
  }

  List<MediaProvider> getActiveProviders() {
    return _providers.where((p) => p.isEnabled).toList();
  }

  void setOfflineMode(bool enabled) {
    _offlineMode = enabled;
  }
  
  /// Sync a provider in the background
  Future<void> syncProvider(String providerId, {bool incremental = true}) async {
    final provider = _providers.firstWhere(
      (p) => p.id == providerId,
      orElse: () => throw Exception('Provider not found'),
    );
    
    try {
      // Trigger provider sync
      // For network providers, this would fetch updates
      // For local provider, this would rescan file system
      if (incremental) {
        // Incremental sync - only fetch changes since last sync
        // TODO: Implement incremental sync logic
      } else {
        // Full sync - fetch everything
        await provider.getArtists();
        await provider.getAlbums();
        await provider.getSongs();
      }
    } catch (e) {
      // Error recovery
      // TODO: Log error and implement retry logic
    }
  }
  
  /// Sync all providers in background
  Future<void> syncAllProviders({bool incremental = true}) async {
    final activeProviders = getActiveProviders();
    for (final provider in activeProviders) {
      try {
        await syncProvider(provider.id, incremental: incremental);
      } catch (e) {
        // Continue with other providers even if one fails
      }
    }
  }
  
  /// Get last sync time for a provider
  DateTime? getLastSyncTime(String providerId) {
    // TODO: Store and retrieve last sync time from database
    return null;
  }
  
  /// Set last sync time for a provider
  void setLastSyncTime(String providerId, DateTime time) {
    // TODO: Store last sync time in database
  }

  Future<List<Artist>> getArtists() async {
    final providers = _offlineMode 
        ? _providers.where((p) => p is LocalProvider).toList()
        : getActiveProviders();

    final allArtists = <String, Artist>{};

    for (final provider in providers) {
      try {
        final artists = await provider.getArtists();
        for (final artist in artists) {
          final key = artist.name.toLowerCase();
          if (allArtists.containsKey(key)) {
            // Merge artist data
            final existing = allArtists[key]!;
            allArtists[key] = Artist(
              id: existing.id,
              name: existing.name,
              albumCount: existing.albumCount! + (artist.albumCount ?? 0),
              trackCount: existing.trackCount! + (artist.trackCount ?? 0),
              providerId: existing.providerId,
            );
          } else {
            allArtists[key] = artist;
          }
        }
      } catch (e) {
        // Handle provider errors
      }
    }

    return allArtists.values.toList();
  }

  Future<List<Album>> getAlbums({String? artistId}) async {
    final providers = _offlineMode 
        ? _providers.where((p) => p is LocalProvider).toList()
        : getActiveProviders();

    final allAlbums = <String, Album>{};

    for (final provider in providers) {
      try {
        final albums = await provider.getAlbums();
        for (final album in albums) {
          if (artistId != null && album.artistId != artistId) continue;
          
          final key = '${album.artist.toLowerCase()}::${album.title.toLowerCase()}';
          if (allAlbums.containsKey(key)) {
            // Merge album data
            final existing = allAlbums[key]!;
            allAlbums[key] = Album(
              id: existing.id,
              title: existing.title,
              artist: existing.artist,
              coverArtUri: existing.coverArtUri ?? album.coverArtUri,
              trackCount: existing.trackCount! + (album.trackCount ?? 0),
              providerId: existing.providerId,
            );
          } else {
            allAlbums[key] = album;
          }
        }
      } catch (e) {
        // Handle provider errors
      }
    }

    return allAlbums.values.toList();
  }

  Future<List<Song>> getSongs({String? albumId, String? artistId}) async {
    final providers = _offlineMode 
        ? _providers.where((p) => p is LocalProvider).toList()
        : getActiveProviders();

    final allSongs = <String, Song>{};

    for (final provider in providers) {
      try {
        final songs = await provider.getSongs();
        for (final song in songs) {
          if (albumId != null && song.albumId != albumId) continue;
          if (artistId != null) {
            // Match by artist name for now
            final providerArtists = await provider.getArtists();
            final matchingArtist = providerArtists.firstWhere(
              (a) => a.name == song.artist,
              orElse: () => throw Exception('Artist not found'),
            );
            if (matchingArtist.id != artistId) continue;
          }

          final key = song.uri;
          if (!allSongs.containsKey(key)) {
            allSongs[key] = song;
          }
        }
      } catch (e) {
        // Handle provider errors
      }
    }

    return allSongs.values.toList();
  }

  Future<List<Playlist>> getPlaylists() async {
    final providers = _offlineMode 
        ? _providers.where((p) => p is LocalProvider).toList()
        : getActiveProviders();

    final allPlaylists = <String, Playlist>{};

    for (final provider in providers) {
      try {
        final playlists = await provider.getPlaylists();
        for (final playlist in playlists) {
          final key = playlist.id;
          if (!allPlaylists.containsKey(key)) {
            allPlaylists[key] = playlist;
          }
        }
      } catch (e) {
        // Handle provider errors
      }
    }

    return allPlaylists.values.toList();
  }

  Future<Stream<List<int>>> getAudioStream(String songId, String providerId) async {
    final provider = _providers.firstWhere(
      (p) => p.id == providerId,
      orElse: () => throw Exception('Provider not found'),
    );
    return provider.getAudioStream(songId);
  }

  Future<String?> getCoverArtUrl(String albumId, String providerId) async {
    final provider = _providers.firstWhere(
      (p) => p.id == providerId,
      orElse: () => throw Exception('Provider not found'),
    );
    return provider.getCoverArtUrl(albumId);
  }
}

final providerRepositoryProvider = Provider<ProviderRepository>((ref) {
  return ProviderRepository();
});
