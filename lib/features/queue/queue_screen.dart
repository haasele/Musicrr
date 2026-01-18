import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/audio/audio_engine.dart';
import '../../core/audio/playback_queue.dart';
import '../../core/models/song.dart';

class QueueScreen extends ConsumerWidget {
  const QueueScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.watch(audioEngineProvider);
    final queue = engine.queue;
    final playbackStateAsync = ref.watch(playbackStateProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Queue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle),
            onPressed: () {
              engine.setShuffle(!queue.shuffleEnabled);
            },
            color: queue.shuffleEnabled
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.repeat),
            onSelected: (value) {
              final mode = value == 'none'
                  ? RepeatMode.none
                  : value == 'one'
                      ? RepeatMode.one
                      : RepeatMode.all;
              engine.setRepeat(mode);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'none',
                child: Row(
                  children: [
                    Icon(
                      queue.repeatMode == RepeatMode.none
                          ? Icons.check
                          : Icons.check_box_outline_blank,
                    ),
                    const SizedBox(width: 8),
                    const Text('No Repeat'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'one',
                child: Row(
                  children: [
                    Icon(
                      queue.repeatMode == RepeatMode.one
                          ? Icons.check
                          : Icons.check_box_outline_blank,
                    ),
                    const SizedBox(width: 8),
                    const Text('Repeat One'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(
                      queue.repeatMode == RepeatMode.all
                          ? Icons.check
                          : Icons.check_box_outline_blank,
                    ),
                    const SizedBox(width: 8),
                    const Text('Repeat All'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: queue.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.queue_music,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Queue is empty',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            )
          : playbackStateAsync.when(
              data: (state) => _buildQueueList(context, ref, queue, state.currentSong),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
    );
  }
  
  Widget _buildQueueList(
    BuildContext context,
    WidgetRef ref,
    PlaybackQueue queue,
    Song? currentSong,
  ) {
    return ReorderableListView.builder(
      itemCount: queue.tracks.length,
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex--;
        queue.reorder(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final song = queue.tracks[index];
        final isCurrent = song.id == currentSong?.id;
        
        return ListTile(
          key: ValueKey(song.id),
          leading: isCurrent
              ? Icon(
                  Icons.play_arrow,
                  color: Theme.of(context).colorScheme.primary,
                )
              : Text(
                  '${index + 1}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
          title: Text(
            song.title,
            style: TextStyle(
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Text('${song.artist} • ${song.album}'),
          trailing: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              queue.removeAt(index);
            },
          ),
          onTap: () {
            ref.read(audioEngineProvider).playFromQueue(index);
          },
        );
      },
    );
  }
}
