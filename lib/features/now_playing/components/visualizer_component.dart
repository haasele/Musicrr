import 'package:flutter/material.dart';
import 'now_playing_component.dart';
import '../layout/layout_engine.dart';

class VisualizerComponent extends NowPlayingComponent {
  VisualizerComponent()
      : super(
          id: 'visualizer',
          type: 'visualizer',
          defaultConfig: const {
            'presetPath': null, // Path to .milk preset
            'showControls': false,
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
    // Placeholder - will integrate with native visualizer engine
    // For now, show a placeholder that indicates visualizer would render here
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.graphic_eq,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              'Visualizer',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
