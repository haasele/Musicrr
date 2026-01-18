import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import 'analytics_service.dart';

class RecommendationEngine {
  final AnalyticsService _analytics;
  
  RecommendationEngine(this._analytics);
  
  /// Calculate recommendation score for a song
  Future<double> calculateScore(Song song) async {
    final frequency = await _analytics.getPlayFrequency(song.id);
    final lastPlayed = await _analytics.getLastPlayed(song.id);
    final skipRate = await _analytics.getSkipRate(song.id);
    final completionRate = await _analytics.getCompletionRate(song.id);
    
    // Frequency score (0-1, logarithmic scale)
    final frequencyScore = _logScore(frequency, maxValue: 100);
    
    // Recency score (0-1, exponential decay)
    final recencyScore = _calculateRecencyScore(lastPlayed);
    
    // Skip rate penalty (0-1, lower skip rate = higher score)
    final skipRatePenalty = 1.0 - skipRate;
    
    // Completion rate bonus (0-1, higher completion = higher score)
    final completionBonus = completionRate;
    
    // Weighted combination
    final score = (frequencyScore * 0.3) +
        (recencyScore * 0.3) +
        (skipRatePenalty * 0.2) +
        (completionBonus * 0.2);
    
    return score.clamp(0.0, 1.0);
  }
  
  /// Get recommended songs based on current song
  Future<List<Song>> getSimilarSongs(Song currentSong, List<Song> allSongs, {int limit = 20}) async {
    // Simple similarity: same artist or genre
    final similar = allSongs.where((song) {
      if (song.id == currentSong.id) return false;
      
      // Same artist
      if (song.artist == currentSong.artist) return true;
      
      // Same genre
      if (song.genre != null &&
          currentSong.genre != null &&
          song.genre == currentSong.genre) {
        return true;
      }
      
      return false;
    }).toList();
    
    // Score and sort
    final scored = <MapEntry<Song, double>>[];
    for (final song in similar) {
      final score = await calculateScore(song);
      scored.add(MapEntry(song, score));
    }
    
    scored.sort((a, b) => b.value.compareTo(a.value));
    
    return scored.take(limit).map((e) => e.key).toList();
  }
  
  /// Get top recommended songs
  Future<List<Song>> getTopRecommended(List<Song> allSongs, {int limit = 20}) async {
    final scored = <MapEntry<Song, double>>[];
    
    for (final song in allSongs) {
      final score = await calculateScore(song);
      scored.add(MapEntry(song, score));
    }
    
    scored.sort((a, b) => b.value.compareTo(a.value));
    
    return scored.take(limit).map((e) => e.key).toList();
  }
  
  double _logScore(int value, {int maxValue = 100}) {
    if (value <= 0) return 0.0;
    if (value >= maxValue) return 1.0;
    return (value / maxValue) * 0.8 + 0.2; // Scale to 0.2-1.0
  }
  
  double _calculateRecencyScore(DateTime? lastPlayed) {
    if (lastPlayed == null) return 0.0;
    
    final daysSince = DateTime.now().difference(lastPlayed).inDays;
    
    // Exponential decay: 1.0 for today, ~0.5 for 7 days, ~0.1 for 30 days
    if (daysSince == 0) return 1.0;
    if (daysSince >= 30) return 0.1;
    
    return 1.0 / (1.0 + (daysSince / 7.0));
  }
}

final recommendationEngineProvider = Provider<RecommendationEngine>((ref) {
  final analytics = ref.watch(analyticsServiceProvider);
  return RecommendationEngine(analytics);
});
