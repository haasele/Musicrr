import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import 'analytics_service.dart';
import 'recommendation_engine.dart';

class PlaylistGenerator {
  final AnalyticsService _analytics;
  final RecommendationEngine _recommendationEngine;
  
  PlaylistGenerator(this._analytics, this._recommendationEngine);
  
  /// Generate "Frequently Played" playlist
  Future<Playlist> generateFrequentlyPlayed(List<Song> allSongs, {int limit = 50}) async {
    final songIds = await _analytics.getMostPlayedSongIds(limit);
    final songs = allSongs.where((s) => songIds.contains(s.id)).toList();
    
    // Sort by frequency
    songs.sort((a, b) {
      final aIndex = songIds.indexOf(a.id);
      final bIndex = songIds.indexOf(b.id);
      return aIndex.compareTo(bIndex);
    });
    
    return Playlist(
      id: 'frequently_played',
      name: 'Frequently Played',
      description: 'Your most played songs',
      songIds: songs.map((s) => s.id).toList(),
      createdAt: DateTime.now(),
    );
  }
  
  /// Generate "Recently Added" playlist (songs added in last N days)
  Future<Playlist> generateRecentlyAdded(List<Song> allSongs, {int days = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final recentSongs = allSongs.where((song) {
      // This would need creation date in Song model
      // For now, use a placeholder
      return true; // Placeholder
    }).toList();
    
    return Playlist(
      id: 'recently_added',
      name: 'Recently Added',
      description: 'Songs added in the last $days days',
      songIds: recentSongs.map((s) => s.id).toList(),
      createdAt: DateTime.now(),
    );
  }
  
  /// Generate "Forgotten Tracks" playlist (not played in N days)
  Future<Playlist> generateForgottenTracks(List<Song> allSongs, {int days = 90, int limit = 50}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final forgotten = <Song>[];
    
    for (final song in allSongs) {
      final lastPlayed = await _analytics.getLastPlayed(song.id);
      if (lastPlayed == null || lastPlayed.isBefore(cutoffDate)) {
        forgotten.add(song);
        if (forgotten.length >= limit) break;
      }
    }
    
    return Playlist(
      id: 'forgotten_tracks',
      name: 'Forgotten Tracks',
      description: 'Songs not played in $days days',
      songIds: forgotten.map((s) => s.id).toList(),
      createdAt: DateTime.now(),
    );
  }
  
  /// Generate "Similar Artists" playlist based on current song
  Future<Playlist> generateSimilarArtists(Song currentSong, List<Song> allSongs, {int limit = 30}) async {
    final similar = await _recommendationEngine.getSimilarSongs(currentSong, allSongs, limit: limit);
    
    return Playlist(
      id: 'similar_artists',
      name: 'Similar to ${currentSong.title}',
      description: 'Songs similar to ${currentSong.artist}',
      songIds: similar.map((s) => s.id).toList(),
      createdAt: DateTime.now(),
    );
  }
  
  /// Generate "Discover Weekly" style playlist
  Future<Playlist> generateDiscoverWeekly(List<Song> allSongs, {int limit = 30}) async {
    // Mix of recommendations and forgotten tracks
    final topRecommended = await _recommendationEngine.getTopRecommended(allSongs, limit: limit ~/ 2);
    final forgotten = await generateForgottenTracks(allSongs, days: 60, limit: limit ~/ 2);
    
    final combined = <Song>[
      ...topRecommended,
      ...allSongs.where((s) => forgotten.songIds.contains(s.id)).take(limit ~/ 2),
    ];
    
    // Shuffle for variety
    combined.shuffle();
    
    return Playlist(
      id: 'discover_weekly',
      name: 'Discover Weekly',
      description: 'Personalized recommendations',
      songIds: combined.take(limit).map((s) => s.id).toList(),
      createdAt: DateTime.now(),
    );
  }
}

final playlistGeneratorProvider = Provider<PlaylistGenerator>((ref) {
  final analytics = ref.watch(analyticsServiceProvider);
  final recommendationEngine = ref.watch(recommendationEngineProvider);
  return PlaylistGenerator(analytics, recommendationEngine);
});
