import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/audio/audio_engine.dart';
import '../../core/storage/now_playing_preset_repository.dart';
import '../../shared/widgets/cover_art_widget.dart';
import 'layout/layout_preset.dart';
import 'presets/builtin_presets.dart';
import 'edit_mode/edit_mode_screen.dart';

class NowPlayingScreen extends ConsumerStatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen> {
  @override
  Widget build(BuildContext context) {
    final playbackStateAsync = ref.watch(playbackStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _openEditMode(context, ref),
            tooltip: 'Edit layout',
          ),
        ],
      ),
      body: playbackStateAsync.when(
        data: (state) {
          if (state.currentSong == null) {
            return const Center(
              child: Text('No song playing'),
            );
          }

          return Column(
            children: [
              // Cover art
              Expanded(
                child: Center(
                  child: CoverArtWidget(
                    coverArtUri: state.currentSong?.coverArtUri,
                    width: 300,
                    height: 300,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              // Track info
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Semantics(
                      label: 'Track title',
                      child: Text(
                        state.currentSong!.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Semantics(
                      label: 'Artist name',
                      child: Text(
                        state.currentSong!.artist,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              // Progress bar - using Material 3 slider with fluid seeking
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _FluidProgressSlider(
                  positionMs: state.positionMs,
                  durationMs: state.durationMs,
                  onSeek: (position) {
                    ref.read(audioEngineProvider).seek(position);
                  },
                ),
              ),
              // Controls
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Semantics(
                      label: 'Previous track',
                      button: true,
                      child: IconButton(
                        icon: const Icon(Icons.skip_previous),
                        iconSize: 32,
                        onPressed: () {
                          ref.read(audioEngineProvider).previous();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Semantics(
                      label: state.state == PlaybackState.playing
                          ? 'Pause playback'
                          : 'Resume playback',
                      button: true,
                      child: IconButton(
                        icon: Icon(
                          state.state == PlaybackState.playing
                              ? Icons.pause_circle
                              : Icons.play_circle,
                        ),
                        iconSize: 64,
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
                    const SizedBox(width: 16),
                    Semantics(
                      label: 'Next track',
                      button: true,
                      child: IconButton(
                        icon: const Icon(Icons.skip_next),
                        iconSize: 32,
                        onPressed: () {
                          ref.read(audioEngineProvider).next();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Future<void> _openEditMode(BuildContext context, WidgetRef ref) async {
    try {
      final repository = ref.read(nowPlayingPresetRepositoryProvider);

      // Get current song's provider and album info
      final playbackState = ref.read(playbackStateProvider).value;
      final currentSong = playbackState?.currentSong;
      final providerId = currentSong?.providerId;
      final albumId = currentSong?.albumId;

      // Get active preset (priority: album → provider → global)
      NowPlayingLayout? currentLayout = await repository.getActivePreset(
        sourceId: providerId,
        albumId: albumId,
      );

      // If no preset exists, create a default one
      if (currentLayout == null) {
        final defaultPresets = BuiltinPresets.createDefaultPresets();
        currentLayout = defaultPresets.first; // Use Classic preset as default

        // Save it as the global default
        await repository.savePreset(currentLayout);
      }

      // Navigate to edit mode
      if (!mounted) return;
      final navigatorContext = context;
      final result = await Navigator.push<bool>(
        navigatorContext,
        MaterialPageRoute(
          builder: (context) => EditModeScreen(
            initialLayout: currentLayout!,
          ),
        ),
      );

      // If layout was saved, refresh the screen
      if (result == true && mounted) {
        setState(() {});
      }
    } catch (e) {
      if (!mounted) return;
      final messengerContext = context;
      ScaffoldMessenger.of(messengerContext).showSnackBar(
        SnackBar(content: Text('Error opening edit mode: $e')),
      );
    }
  }
}

/// Fluid progress slider that seeks while dragging without pausing
class _FluidProgressSlider extends StatefulWidget {
  final int positionMs;
  final int durationMs;
  final void Function(int positionMs) onSeek;

  const _FluidProgressSlider({
    required this.positionMs,
    required this.durationMs,
    required this.onSeek,
  });

  @override
  State<_FluidProgressSlider> createState() => _FluidProgressSliderState();
}

class _FluidProgressSliderState extends State<_FluidProgressSlider> {
  double? _dragValue;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final displayValue = _isDragging && _dragValue != null
        ? _dragValue!
        : (widget.durationMs > 0 ? widget.positionMs.toDouble() : 0.0);
    final max = widget.durationMs > 0 ? widget.durationMs.toDouble() : 100.0;

    return Column(
      children: [
        Semantics(
          label: 'Playback progress',
          value:
              '${_formatDuration(widget.positionMs)} of ${_formatDuration(widget.durationMs)}',
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Theme.of(context).colorScheme.primary,
              inactiveTrackColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              thumbColor: Theme.of(context).colorScheme.primary,
              trackHeight: 4.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: displayValue,
              max: max,
              onChanged: (value) {
                setState(() {
                  _isDragging = true;
                  _dragValue = value;
                });
                // Seek immediately while dragging (fluid)
                widget.onSeek(value.toInt());
              },
              onChangeEnd: (value) {
                setState(() {
                  _isDragging = false;
                  _dragValue = null;
                });
                // Final seek on release
                widget.onSeek(value.toInt());
              },
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(widget.positionMs),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            Text(
              _formatDuration(widget.durationMs),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
