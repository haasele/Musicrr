import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/provider_repository.dart';
import '../../core/recommendations/playlist_generator.dart';
import '../../core/recommendations/analytics_service.dart';
import '../../core/recommendations/recommendation_engine.dart';
import '../../core/models/playlist.dart';
import '../../core/models/song.dart';
import 'recommendation_widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(providerRepositoryProvider);
    final playlistGenerator = ref.watch(playlistGeneratorProvider);
    final analytics = ref.watch(analyticsServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh recommendations
        },
        child: FutureBuilder<List<Song>>(
          future: _loadAllSongs(repository),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading music',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final allSongs = snapshot.data ?? [];

            if (allSongs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.music_off,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No music found',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add music folders in Library settings',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () {
                        try {
                          context.go('/library');
                        } catch (e) {
                          // Fallback if go_router is not available
                          debugPrint('Navigation error: $e');
                        }
                      },
                      icon: const Icon(Icons.library_music),
                      label: const Text('Go to Library'),
                    ),
                  ],
                ),
              );
            }

            return ListView(
              children: [
                // Recently Played
                RecommendationWidget(
                  title: 'Recently Played',
                  subtitle: 'Continue where you left off',
                  loadSongs: () async {
                    final songIds = await analytics.getRecentlyPlayedSongIds(7);
                    return allSongs
                        .where((s) => songIds.contains(s.id))
                        .toList();
                  },
                ),

                // Auto-generated playlists
                Column(
                  children: [
                    // Frequently Played
                    FutureBuilder<Playlist>(
                      future:
                          playlistGenerator.generateFrequentlyPlayed(allSongs),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox.shrink();
                        final playlist = snapshot.data!;
                        return AutoPlaylistWidget(
                          playlist: playlist,
                          loadSongs: () async {
                            return allSongs
                                .where((s) => playlist.songIds.contains(s.id))
                                .toList();
                          },
                        );
                      },
                    ),

                    // Discover Weekly
                    FutureBuilder<Playlist>(
                      future:
                          playlistGenerator.generateDiscoverWeekly(allSongs),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox.shrink();
                        final playlist = snapshot.data!;
                        return AutoPlaylistWidget(
                          playlist: playlist,
                          loadSongs: () async {
                            return allSongs
                                .where((s) => playlist.songIds.contains(s.id))
                                .toList();
                          },
                        );
                      },
                    ),

                    // Forgotten Tracks
                    FutureBuilder<Playlist>(
                      future:
                          playlistGenerator.generateForgottenTracks(allSongs),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox.shrink();
                        final playlist = snapshot.data!;
                        return AutoPlaylistWidget(
                          playlist: playlist,
                          loadSongs: () async {
                            return allSongs
                                .where((s) => playlist.songIds.contains(s.id))
                                .toList();
                          },
                        );
                      },
                    ),
                  ],
                ),

                // Top Recommendations
                RecommendationWidget(
                  title: 'Recommended for You',
                  subtitle: 'Based on your listening habits',
                  loadSongs: () async {
                    final recommendationEngine =
                        ref.read(recommendationEngineProvider);
                    return recommendationEngine.getTopRecommended(allSongs,
                        limit: 20);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<List<Song>> _loadAllSongs(ProviderRepository repository) async {
    return repository.getSongs();
  }
}
