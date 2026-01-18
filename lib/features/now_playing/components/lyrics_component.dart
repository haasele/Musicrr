import 'package:flutter/material.dart';
import 'now_playing_component.dart';
import '../layout/layout_engine.dart';

class LyricsComponent extends NowPlayingComponent {
  LyricsComponent()
      : super(
          id: 'lyrics',
          type: 'lyrics',
          defaultConfig: const {
            'mode': 'overlay', // 'overlay', 'fullscreen'
            'autoScroll': true,
            'fontSize': 16.0,
            'textAlign': 'center',
          },
        );
  
  @override
  List<SizeOption> getSupportedSizes() {
    return const [
      SizeOption(rowSpan: 2, columnSpan: 2, label: 'Medium'),
      SizeOption(rowSpan: 2, columnSpan: 4, label: 'Wide'),
      SizeOption(rowSpan: 4, columnSpan: 4, label: 'Full Screen'),
    ];
  }
  
  @override
  bool canResizeTo(int rowSpan, int columnSpan) {
    if (rowSpan == 2 && columnSpan == 2) return true;
    if (rowSpan == 2 && columnSpan == 4) return true;
    if (rowSpan == 4 && columnSpan == 4) return true;
    return false;
  }
  
  @override
  Widget build(BuildContext context, Map<String, dynamic> config, NowPlayingState state) {
    // Placeholder - will integrate with lyrics system
    // For now, show a placeholder
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lyrics,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              'Lyrics',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'No lyrics available',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
