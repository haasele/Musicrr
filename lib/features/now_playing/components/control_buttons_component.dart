import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'now_playing_component.dart';
import '../layout/layout_engine.dart';
import '../../../core/audio/audio_engine.dart';

class ControlButtonsComponent extends NowPlayingComponent {
  ControlButtonsComponent()
      : super(
          id: 'control_buttons',
          type: 'control_buttons',
          defaultConfig: const {
            'layout': 'horizontal', // 'horizontal', 'vertical', 'grid'
            'showShuffle': true,
            'showRepeat': true,
            'buttonSize': 'medium', // 'small', 'medium', 'large'
          },
        );
  
  @override
  List<SizeOption> getSupportedSizes() {
    return const [
      SizeOption(rowSpan: 1, columnSpan: 4, label: 'Full Width'),
      SizeOption(rowSpan: 2, columnSpan: 2, label: 'Square'),
      SizeOption(rowSpan: 2, columnSpan: 4, label: 'Wide'),
    ];
  }
  
  @override
  bool canResizeTo(int rowSpan, int columnSpan) {
    if (rowSpan == 1 && columnSpan == 4) return true;
    if (rowSpan == 2 && columnSpan == 2) return true;
    if (rowSpan == 2 && columnSpan == 4) return true;
    return false;
  }
  
  @override
  Widget build(BuildContext context, Map<String, dynamic> config, NowPlayingState state) {
    final layout = config['layout'] as String? ?? 'horizontal';
    final showShuffle = config['showShuffle'] as bool? ?? true;
    final showRepeat = config['showRepeat'] as bool? ?? true;
    final buttonSize = config['buttonSize'] as String? ?? 'medium';
    
    final iconSize = _getIconSize(buttonSize);
    final mainButtonSize = _getMainButtonSize(buttonSize);
    
    final isPlaying = state.playbackState == PlaybackState.playing;
    
    switch (layout) {
      case 'vertical':
        return _buildVerticalLayout(
          context,
          state,
          showShuffle,
          showRepeat,
          iconSize,
          mainButtonSize,
          isPlaying,
        );
      case 'grid':
        return _buildGridLayout(
          context,
          state,
          showShuffle,
          showRepeat,
          iconSize,
          mainButtonSize,
          isPlaying,
        );
      default:
        return _buildHorizontalLayout(
          context,
          state,
          showShuffle,
          showRepeat,
          iconSize,
          mainButtonSize,
          isPlaying,
        );
    }
  }
  
  Widget _buildHorizontalLayout(
    BuildContext context,
    NowPlayingState state,
    bool showShuffle,
    bool showRepeat,
    double iconSize,
    double mainButtonSize,
    bool isPlaying,
  ) {
    return Consumer(
      builder: (context, ref, child) {
        final engine = ref.read(audioEngineProvider);
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showShuffle)
              IconButton(
                icon: const Icon(Icons.shuffle),
                iconSize: iconSize,
                onPressed: () {
                  // TODO: Implement shuffle
                },
              ),
            IconButton(
              icon: const Icon(Icons.skip_previous),
              iconSize: iconSize,
              onPressed: () {
                // TODO: Implement previous track
              },
            ),
            IconButton(
              icon: Icon(isPlaying ? Icons.pause_circle : Icons.play_circle),
              iconSize: mainButtonSize,
              onPressed: () {
                if (isPlaying) {
                  engine.pause();
                } else {
                  engine.resume();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.skip_next),
              iconSize: iconSize,
              onPressed: () {
                // TODO: Implement next track
              },
            ),
            if (showRepeat)
              IconButton(
                icon: const Icon(Icons.repeat),
                iconSize: iconSize,
                onPressed: () {
                  // TODO: Implement repeat
                },
              ),
          ],
        );
      },
    );
  }
  
  Widget _buildVerticalLayout(
    BuildContext context,
    NowPlayingState state,
    bool showShuffle,
    bool showRepeat,
    double iconSize,
    double mainButtonSize,
    bool isPlaying,
  ) {
    return Consumer(
      builder: (context, ref, child) {
        final engine = ref.read(audioEngineProvider);
        
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showShuffle)
              IconButton(
                icon: const Icon(Icons.shuffle),
                iconSize: iconSize,
                onPressed: () {
                  // TODO: Implement shuffle
                },
              ),
            IconButton(
              icon: const Icon(Icons.skip_previous),
              iconSize: iconSize,
              onPressed: () {
                // TODO: Implement previous track
              },
            ),
            IconButton(
              icon: Icon(isPlaying ? Icons.pause_circle : Icons.play_circle),
              iconSize: mainButtonSize,
              onPressed: () {
                if (isPlaying) {
                  engine.pause();
                } else {
                  engine.resume();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.skip_next),
              iconSize: iconSize,
              onPressed: () {
                // TODO: Implement next track
              },
            ),
            if (showRepeat)
              IconButton(
                icon: const Icon(Icons.repeat),
                iconSize: iconSize,
                onPressed: () {
                  // TODO: Implement repeat
                },
              ),
          ],
        );
      },
    );
  }
  
  Widget _buildGridLayout(
    BuildContext context,
    NowPlayingState state,
    bool showShuffle,
    bool showRepeat,
    double iconSize,
    double mainButtonSize,
    bool isPlaying,
  ) {
    return Consumer(
      builder: (context, ref, child) {
        final engine = ref.read(audioEngineProvider);
        
        return GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            if (showShuffle)
              IconButton(
                icon: const Icon(Icons.shuffle),
                iconSize: iconSize,
                onPressed: () {
                  // TODO: Implement shuffle
                },
              )
            else
              const SizedBox.shrink(),
            IconButton(
              icon: const Icon(Icons.skip_previous),
              iconSize: iconSize,
              onPressed: () {
                // TODO: Implement previous track
              },
            ),
            IconButton(
              icon: Icon(isPlaying ? Icons.pause_circle : Icons.play_circle),
              iconSize: mainButtonSize,
              onPressed: () {
                if (isPlaying) {
                  engine.pause();
                } else {
                  engine.resume();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.skip_next),
              iconSize: iconSize,
              onPressed: () {
                // TODO: Implement next track
              },
            ),
            if (showRepeat)
              IconButton(
                icon: const Icon(Icons.repeat),
                iconSize: iconSize,
                onPressed: () {
                  // TODO: Implement repeat
                },
              )
            else
              const SizedBox.shrink(),
          ],
        );
      },
    );
  }
  
  double _getIconSize(String size) {
    switch (size) {
      case 'small':
        return 24;
      case 'large':
        return 40;
      default:
        return 32;
    }
  }
  
  double _getMainButtonSize(String size) {
    switch (size) {
      case 'small':
        return 48;
      case 'large':
        return 80;
      default:
        return 64;
    }
  }
}
