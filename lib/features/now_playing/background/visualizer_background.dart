import 'package:flutter/material.dart';
import '../components/visualizer_component.dart';
import '../layout/layout_engine.dart';

class VisualizerBackground extends StatelessWidget {
  final Widget child;
  final Map<String, dynamic> visualizerConfig;
  
  const VisualizerBackground({
    super.key,
    required this.child,
    this.visualizerConfig = const {},
  });
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Visualizer as background layer
        Positioned.fill(
          child: Opacity(
            opacity: 0.3, // Semi-transparent background
            child: VisualizerComponent().build(
              context,
              visualizerConfig,
              const NowPlayingState(), // Placeholder state
            ),
          ),
        ),
        // Content on top
        child,
      ],
    );
  }
}
