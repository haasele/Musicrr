import 'package:flutter/material.dart';
import 'now_playing_component.dart';
import '../layout/layout_engine.dart';

class ProgressSliderComponent extends NowPlayingComponent {
  ProgressSliderComponent()
      : super(
          id: 'progress_slider',
          type: 'progress_slider',
          defaultConfig: const {
            'variant': 'material3', // 'simple', 'material3', 'animated_wave'
            'showTimeLabels': true,
            'showThumb': true,
          },
        );
  
  @override
  List<SizeOption> getSupportedSizes() {
    return const [
      SizeOption(rowSpan: 1, columnSpan: 2, label: 'Half Width'),
      SizeOption(rowSpan: 1, columnSpan: 4, label: 'Full Width'),
    ];
  }
  
  @override
  bool canResizeTo(int rowSpan, int columnSpan) {
    return rowSpan == 1 && (columnSpan == 2 || columnSpan == 4);
  }
  
  @override
  Widget build(BuildContext context, Map<String, dynamic> config, NowPlayingState state) {
    final variant = config['variant'] as String? ?? 'material3';
    final showTimeLabels = config['showTimeLabels'] as bool? ?? true;
    final showThumb = config['showThumb'] as bool? ?? true;
    
    switch (variant) {
      case 'simple':
        return _buildSimpleSlider(context, state, showTimeLabels, showThumb);
      case 'material3':
        return _buildMaterial3Slider(context, state, showTimeLabels, showThumb);
      case 'animated_wave':
        return _buildAnimatedWaveSlider(context, state, showTimeLabels);
      default:
        return _buildMaterial3Slider(context, state, showTimeLabels, showThumb);
    }
  }
  
  Widget _buildSimpleSlider(
    BuildContext context,
    NowPlayingState state,
    bool showTimeLabels,
    bool showThumb,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Slider(
          value: state.durationMs > 0
              ? state.positionMs.toDouble()
              : 0.0,
          max: state.durationMs > 0
              ? state.durationMs.toDouble()
              : 100.0,
          onChanged: (value) {
            state.onSeek?.call(value.toInt());
          },
        ),
        if (showTimeLabels)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(state.positionMs)),
              Text(_formatDuration(state.durationMs)),
            ],
          ),
      ],
    );
  }
  
  Widget _buildMaterial3Slider(
    BuildContext context,
    NowPlayingState state,
    bool showTimeLabels,
    bool showThumb,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Theme.of(context).colorScheme.primary,
            inactiveTrackColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            thumbColor: Theme.of(context).colorScheme.primary,
            trackHeight: 4.0,
            thumbShape: showThumb
                ? const RoundSliderThumbShape(enabledThumbRadius: 10)
                : const RoundSliderThumbShape(enabledThumbRadius: 0),
          ),
          child: Slider(
            value: state.durationMs > 0
                ? state.positionMs.toDouble()
                : 0.0,
            max: state.durationMs > 0
                ? state.durationMs.toDouble()
                : 100.0,
            onChanged: (value) {
              // Seek immediately while dragging (fluid)
              state.onSeek?.call(value.toInt());
            },
            onChangeEnd: (value) {
              // Final seek on release
              state.onSeek?.call(value.toInt());
            },
          ),
        ),
        if (showTimeLabels)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(state.positionMs),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  _formatDuration(state.durationMs),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
  
  Widget _buildAnimatedWaveSlider(
    BuildContext context,
    NowPlayingState state,
    bool showTimeLabels,
  ) {
    return _FluidWaveSlider(
      positionMs: state.positionMs,
      durationMs: state.durationMs,
      onSeek: state.onSeek,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: CustomPaint(
              painter: _WaveformPainter(
                progress: state.durationMs > 0
                    ? state.positionMs / state.durationMs
                    : 0.0,
                color: Theme.of(context).colorScheme.primary,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          if (showTimeLabels)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(state.positionMs),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    _formatDuration(state.durationMs),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Widget wrapper for fluid wave slider seeking
class _FluidWaveSlider extends StatefulWidget {
  final int positionMs;
  final int durationMs;
  final void Function(int positionMs)? onSeek;
  final Widget child;
  
  const _FluidWaveSlider({
    required this.positionMs,
    required this.durationMs,
    this.onSeek,
    required this.child,
  });
  
  @override
  State<_FluidWaveSlider> createState() => _FluidWaveSliderState();
}

class _FluidWaveSliderState extends State<_FluidWaveSlider> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        final RenderBox? box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          final localPosition = box.globalToLocal(details.globalPosition);
          final width = box.size.width;
          final progress = (localPosition.dx / width).clamp(0.0, 1.0);
          final seekPosition = (progress * widget.durationMs).toInt();
          // Seek immediately while dragging (fluid)
          widget.onSeek?.call(seekPosition);
        }
      },
      onHorizontalDragEnd: (details) {
        final RenderBox? box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          final localPosition = box.globalToLocal(details.globalPosition);
          final width = box.size.width;
          final progress = (localPosition.dx / width).clamp(0.0, 1.0);
          final seekPosition = (progress * widget.durationMs).toInt();
          // Final seek on release
          widget.onSeek?.call(seekPosition);
        }
      },
      child: widget.child,
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  
  _WaveformPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Draw background
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(12),
      ),
      bgPaint,
    );
    
    // Draw waveform
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final waveCount = 40;
    final waveWidth = size.width / waveCount;
    final progressWidth = size.width * progress;
    final centerY = size.height / 2;
    
    for (int i = 0; i < waveCount; i++) {
      final x = i * waveWidth + waveWidth / 2;
      if (x > progressWidth) {
        // Draw inactive waves in muted color
        final mutedPaint = Paint()
          ..color = color.withOpacity(0.3)
          ..style = PaintingStyle.fill;
        final height = ((i % 5) + 1) * 3.0;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(x, centerY),
              width: waveWidth * 0.6,
              height: height,
            ),
            const Radius.circular(2),
          ),
          mutedPaint,
        );
      } else {
        // Draw active waves
        final height = ((i % 5) + 1) * 8.0;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(x, centerY),
              width: waveWidth * 0.6,
              height: height,
            ),
            const Radius.circular(2),
          ),
          paint,
        );
      }
    }
    
    // Draw progress indicator line
    if (progress > 0) {
      final linePaint = Paint()
        ..color = color
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(progressWidth, 0),
        Offset(progressWidth, size.height),
        linePaint,
      );
    }
  }
  
  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
