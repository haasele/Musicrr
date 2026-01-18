import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/playlist.dart';
import '../../core/models/song.dart';
import '../../core/audio/audio_engine.dart';
import '../../shared/widgets/cover_art_widget.dart';

class RecommendationWidget extends ConsumerWidget {
  final String title;
  final String? subtitle;
  final Future<List<Song>> Function() loadSongs;
  final VoidCallback? onSeeAll;
  
  const RecommendationWidget({
    super.key,
    required this.title,
    this.subtitle,
    required this.loadSongs,
    this.onSeeAll,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<Song>>(
      future: loadSongs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        
        final songs = snapshot.data!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                    ],
                  ),
                  if (onSeeAll != null)
                    TextButton(
                      onPressed: onSeeAll,
                      child: const Text('See All'),
                    ),
                ],
              ),
            ),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  final song = songs[index];
                  return _SongCard(song: song);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SongCard extends ConsumerWidget {
  final Song song;
  
  const _SongCard({required this.song});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () {
          ref.read(audioEngineProvider).play(song);
        },
        child: Container(
          width: 140,
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover art
              CoverArtWidget(
                coverArtUri: song.coverArtUri,
                width: double.infinity,
                height: 100,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 8),
              Text(
                song.title,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                song.artist,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AutoPlaylistWidget extends ConsumerWidget {
  final Playlist playlist;
  final Future<List<Song>> Function() loadSongs;
  
  const AutoPlaylistWidget({
    super.key,
    required this.playlist,
    required this.loadSongs,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<Song>>(
      future: loadSongs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        
        final songs = snapshot.data!;
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: InkWell(
            onTap: () {
              // Add all songs to queue and play first
              final engine = ref.read(audioEngineProvider);
              engine.queue.clear();
              engine.queue.addAll(songs);
              if (songs.isNotEmpty) {
                engine.play(songs.first);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CoverArtWidget(
                    coverArtUri: playlist.coverArtUri,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(12),
                    placeholder: Icon(
                      Icons.playlist_play,
                      size: 40,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playlist.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (playlist.description != null)
                          Text(
                            playlist.description!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 4),
                        Text(
                          '${songs.length} songs',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.play_arrow,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
