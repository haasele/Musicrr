import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/audio/audio_engine.dart';
import '../../shared/widgets/cover_art_widget.dart';

class MiniPlayerBar extends ConsumerWidget {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbackStateAsync = ref.watch(playbackStateProvider);

    return playbackStateAsync.when(
      data: (state) {
        if (state.currentSong == null || state.state == PlaybackState.idle) {
          return const SizedBox.shrink();
        }

        return Semantics(
          label: 'Now playing: ${state.currentSong?.title ?? 'Unknown'} by ${state.currentSong?.artist ?? 'Unknown Artist'}',
          hint: 'Double tap to open Now Playing screen',
          button: true,
          child: GestureDetector(
            onTap: () {
              context.push('/now-playing');
            },
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Cover art thumbnail
                  Semantics(
                    label: 'Album cover art',
                    image: true,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: CoverArtWidget(
                        coverArtUri: state.currentSong?.coverArtUri,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  // Song info
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          label: 'Track title',
                          child: Text(
                            state.currentSong?.title ?? 'Unknown',
                            style: Theme.of(context).textTheme.bodyLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Semantics(
                          label: 'Artist name',
                          child: Text(
                            state.currentSong?.artist ?? 'Unknown Artist',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Play/Pause button
                  Semantics(
                    label: state.state == PlaybackState.playing ? 'Pause playback' : 'Resume playback',
                    button: true,
                    child: IconButton(
                      icon: Icon(
                        state.state == PlaybackState.playing
                            ? Icons.pause
                            : Icons.play_arrow,
                      ),
                      onPressed: () {
                        final engine = ref.read(audioEngineProvider);
                        if (state.state == PlaybackState.playing) {
                          engine.pause();
                        } else {
                          engine.resume();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}
