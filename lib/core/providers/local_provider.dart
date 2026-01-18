import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../storage/storage_permission_service.dart';
import 'metadata_extractor.dart';
import 'media_provider.dart';
import '../models/artist.dart';
import '../models/album.dart';
import '../models/song.dart';
import '../models/playlist.dart';

class LocalProvider implements MediaProvider {
  final String _id = const Uuid().v4();
  final String _name = 'Local Files';
  bool _isEnabled = true;
  final List<String> _supportedExtensions = ['.mp3', '.m4a', '.flac', '.wav', '.opus', '.ogg'];
  static const String _musicDirectoriesKey = 'local_provider_music_directories';
  List<String> _musicDirectories = [];
  
  // Cache for songs to avoid repeated scanning
  List<Song>? _cachedSongs;
  DateTime? _lastScanTime;
  static const Duration _cacheValidDuration = Duration(hours: 1); // Cache for 1 hour

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
    // Load saved music directories
    await _loadMusicDirectories();
  }
  
  /// Load music directories from SharedPreferences
  Future<void> _loadMusicDirectories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final directories = prefs.getStringList(_musicDirectoriesKey);
      if (directories != null && directories.isNotEmpty) {
        _musicDirectories = directories;
      }
    } catch (e) {
      // Handle error
    }
  }
  
  /// Set music directories to scan
  Future<void> setMusicDirectories(List<String> directories) async {
    _musicDirectories = directories;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_musicDirectoriesKey, directories);
  }
  
  /// Get current music directories
  List<String> getMusicDirectories() => List.unmodifiable(_musicDirectories);
  
  /// Add a music directory
  Future<void> addMusicDirectory(String directory) async {
    final normalizedPath = directory.trim();
    if (normalizedPath.isEmpty) {
      throw Exception('Directory path cannot be empty');
    }
    
    // Normalize the path (remove trailing slashes, etc.)
    final dir = Directory(normalizedPath);
    if (!await dir.exists()) {
      throw Exception('Directory does not exist: $normalizedPath');
    }
    
    if (!_musicDirectories.contains(normalizedPath)) {
      _musicDirectories.add(normalizedPath);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_musicDirectoriesKey, _musicDirectories);
      print('LocalProvider: Added directory: $normalizedPath');
      print('LocalProvider: Total directories: ${_musicDirectories.length}');
      // Clear cache when adding a new directory
      await clearCache();
    } else {
      print('LocalProvider: Directory already added: $normalizedPath');
    }
  }
  
  /// Remove a music directory
  Future<void> removeMusicDirectory(String directory) async {
    _musicDirectories.remove(directory);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_musicDirectoriesKey, _musicDirectories);
    // Clear cache when removing a directory
    await clearCache();
  }

  @override
  Future<void> dispose() async {
    // Cleanup logic if needed
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
        id: 'local_artist_${entry.key.hashCode}',
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
      // Find first song with cover art, or use first song's cover art
      final coverArtSong = songs.firstWhere(
        (s) => s.coverArtUri != null && s.coverArtUri!.isNotEmpty,
        orElse: () => firstSong,
      );
      return Album(
        id: 'local_album_${entry.key.hashCode}',
        title: firstSong.album,
        artist: firstSong.artist,
        coverArtUri: coverArtSong.coverArtUri,
        trackCount: songs.length,
        providerId: id,
      );
    }).toList();
  }

  @override
  Future<List<Song>> getSongs() async {
    // Return cached songs if available and still valid
    if (_cachedSongs != null && _lastScanTime != null) {
      final age = DateTime.now().difference(_lastScanTime!);
      if (age < _cacheValidDuration) {
        print('LocalProvider: Returning ${_cachedSongs!.length} cached songs');
        return _cachedSongs!;
      }
    }
    
    final List<Song> songs = [];
    
    try {
      // Check and request storage permissions
      if (Platform.isAndroid) {
        print('LocalProvider: Checking storage permissions...');
        try {
          final hasPermission = await StoragePermissionService.hasStoragePermission();
          if (!hasPermission) {
            print('LocalProvider: Storage permission not granted, requesting...');
            final granted = await StoragePermissionService.requestStoragePermission();
            if (!granted) {
              print('LocalProvider: Storage permission denied');
              // Return cached songs if available, otherwise empty list
              return _cachedSongs ?? [];
            }
            print('LocalProvider: Storage permission granted');
          } else {
            print('LocalProvider: Storage permission already granted');
          }
        } catch (e, stackTrace) {
          print('LocalProvider: Error checking/requesting permissions: $e\n$stackTrace');
          // Return cached songs if available, otherwise empty list
          return _cachedSongs ?? [];
        }
      }
      
      // If custom directories are set, use them
      if (_musicDirectories.isNotEmpty) {
        print('LocalProvider: Scanning ${_musicDirectories.length} directories');
        for (final dirPath in _musicDirectories) {
          print('LocalProvider: Scanning directory: $dirPath');
          final directory = Directory(dirPath);
          if (await directory.exists()) {
            print('LocalProvider: Directory exists, starting scan...');
            await _scanDirectory(directory, songs);
            print('LocalProvider: Found ${songs.length} songs so far');
          } else {
            print('LocalProvider: Directory does not exist: $dirPath');
          }
        }
      } else {
        // Fallback to default music directory
        final directory = await _getMusicDirectory();
        if (directory != null) {
          await _scanDirectory(directory, songs);
        }
      }
      
      // Cache the results
      _cachedSongs = songs;
      _lastScanTime = DateTime.now();
    } catch (e) {
      print('LocalProvider: Error in getSongs: $e');
      // Return cached songs if available, otherwise rethrow
      if (_cachedSongs != null) {
        return _cachedSongs!;
      }
      rethrow;
    }

    print('LocalProvider: Total songs found: ${songs.length}');
    return songs;
  }
  
  /// Force a rescan by clearing the cache
  Future<void> clearCache() async {
    _cachedSongs = null;
    _lastScanTime = null;
  }

  Future<void> _scanDirectory(Directory dir, List<Song> songs) async {
    try {
      if (!await dir.exists()) {
        print('LocalProvider: Directory does not exist: ${dir.path}');
        return;
      }
      
      print('LocalProvider: Scanning directory: ${dir.path}');
      
      // Check if we can list the directory
      try {
        final testList = dir.listSync();
        print('LocalProvider: Directory is readable, found ${testList.length} items');
      } catch (e) {
        print('LocalProvider: Cannot read directory ${dir.path}: $e');
        return;
      }
      
      final entities = dir.list(recursive: false);
      int fileCount = 0;
      int dirCount = 0;
      int songCount = 0;
      
      await for (final entity in entities) {
        try {
          if (entity is File) {
            fileCount++;
            final ext = path.extension(entity.path).toLowerCase();
            print('LocalProvider: Found file: ${entity.path}, extension: $ext');
            if (_supportedExtensions.contains(ext)) {
              print('LocalProvider: File has supported extension, creating song...');
              final song = await _createSongFromFile(entity);
              if (song != null) {
                songs.add(song);
                songCount++;
                print('LocalProvider: Successfully added song: ${song.title}');
              } else {
                print('LocalProvider: Failed to create song from file: ${entity.path}');
              }
            } else {
              print('LocalProvider: File extension $ext not in supported list: $_supportedExtensions');
            }
          } else if (entity is Directory) {
            dirCount++;
            print('LocalProvider: Found subdirectory: ${entity.path}, recursing...');
            await _scanDirectory(entity, songs);
          }
        } catch (e, stackTrace) {
          // Skip individual file/directory errors and continue
          print('LocalProvider: Error processing ${entity.path}: $e');
          print('LocalProvider: Stack trace: $stackTrace');
        }
      }
      
      print('LocalProvider: Finished scanning ${dir.path}: $fileCount files, $dirCount directories, $songCount songs added');
    } catch (e, stackTrace) {
      print('LocalProvider: Error scanning directory ${dir.path}: $e');
      print('LocalProvider: Stack trace: $stackTrace');
      // Don't rethrow - continue with other directories
    }
  }

  Future<Song?> _createSongFromFile(File file) async {
    try {
      final fileName = path.basenameWithoutExtension(file.path);
      final uri = file.uri.toString();

      // Extract metadata using native metadata extractor
      AudioMetadata? metadata;
      String? coverArtUri;
      
      try {
        metadata = await MetadataExtractor.extractMetadata(file.path);
        
        // Extract cover art if available
        if (metadata?.coverArtPath != null) {
          coverArtUri = metadata!.coverArtPath;
        } else {
          // Try to extract cover art to cache directory
          try {
            final cacheDir = await getApplicationCacheDirectory();
            final coverArtPath = path.join(cacheDir.path, 'covers', '${file.path.hashCode}.jpg');
            final coverArtFile = File(coverArtPath);
            
            // Create directory if it doesn't exist
            await coverArtFile.parent.create(recursive: true);
            
            final extractedPath = await MetadataExtractor.extractCoverArt(file.path, coverArtPath);
            if (extractedPath != null && await coverArtFile.exists()) {
              // Ensure we use file:// URI format
              coverArtUri = coverArtFile.uri.toString();
              print('LocalProvider: Extracted cover art to: $coverArtUri');
            } else {
              print('LocalProvider: Cover art extraction returned null or file does not exist');
            }
          } catch (e) {
            print('LocalProvider: Error extracting cover art: $e');
          }
        }
      } catch (e) {
        print('LocalProvider: Error extracting metadata: $e');
      }

      // Use extracted metadata or fallback to filename parsing
      final title = metadata?.title?.isNotEmpty == true 
          ? metadata!.title! 
          : (fileName.split(' - ').length > 1 ? fileName.split(' - ')[1] : fileName);
      
      final artist = metadata?.artist?.isNotEmpty == true 
          ? metadata!.artist! 
          : (fileName.split(' - ').length > 1 ? fileName.split(' - ')[0] : 'Unknown Artist');
      
      final album = metadata?.album?.isNotEmpty == true 
          ? metadata!.album! 
          : 'Unknown Album';

      return Song(
        id: 'local_${file.path.hashCode}',
        title: title,
        artist: artist,
        album: album,
        albumId: album != 'Unknown Album' ? 'local_album_${album.hashCode}' : null,
        duration: metadata?.duration ?? 0,
        uri: uri,
        coverArtUri: coverArtUri,
        trackNumber: metadata?.trackNumber,
        discNumber: metadata?.discNumber,
        genre: metadata?.genre,
        year: metadata?.year,
        providerId: id,
      );
    } catch (e) {
      print('LocalProvider: Error creating song from file ${file.path}: $e');
      return null;
    }
  }

  Future<Directory?> _getMusicDirectory() async {
    if (Platform.isAndroid) {
      // On Android, try to get external storage
      final directory = Directory('/storage/emulated/0/Music');
      if (await directory.exists()) {
        return directory;
      }
    }
    
    // Fallback to app documents directory for testing
    final appDir = await getApplicationDocumentsDirectory();
    final musicDir = Directory(path.join(appDir.path, 'Music'));
    if (await musicDir.exists()) {
      return musicDir;
    }
    
    return null;
  }

  @override
  Future<List<Playlist>> getPlaylists() async {
    // Local playlists would be stored in app data
    // For now, return empty list
    return [];
  }

  @override
  Future<Stream<List<int>>> getAudioStream(String songId) async {
    // The songId format is 'local_${file.path.hashCode}'
    // We need to find the song by ID and use its URI
    final songs = await getSongs();
    final song = songs.firstWhere(
      (s) => s.id == songId,
      orElse: () => throw Exception('Song not found: $songId'),
    );
    
    // Convert URI string back to file path
    final uri = Uri.parse(song.uri);
    final file = File.fromUri(uri);
    
    if (await file.exists()) {
      return file.openRead();
    }
    throw Exception('File not found: ${file.path}');
  }

  @override
  Future<String?> getCoverArtUrl(String albumId) async {
    // For local provider, cover art would be embedded in files or in folder
    // Return null for now - can be enhanced later
    return null;
  }
}
