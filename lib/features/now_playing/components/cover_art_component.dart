import 'package:flutter/material.dart';
import '../../../shared/widgets/cover_art_widget.dart';
import 'now_playing_component.dart';
import '../layout/layout_engine.dart';

class CoverArtComponent extends NowPlayingComponent {
  CoverArtComponent()
      : super(
          id: 'cover_art',
          type: 'cover_art',
          defaultConfig: const {
            'shape': 'square', // 'square', 'circle', 'rounded'
            'borderRadius': 8.0,
            'showShadow': true,
            'animation': 'none', // 'none', 'rotate', 'scale', 'fade'
          },
        );
  
  @override
  List<SizeOption> getSupportedSizes() {
    return const [
      SizeOption(rowSpan: 1, columnSpan: 1, label: 'Small'),
      SizeOption(rowSpan: 2, columnSpan: 2, label: 'Medium'),
      SizeOption(rowSpan: 3, columnSpan: 3, label: 'Large'),
      SizeOption(rowSpan: 4, columnSpan: 4, label: 'Extra Large'),
    ];
  }
  
  @override
  bool canResizeTo(int rowSpan, int columnSpan) {
    // Cover art should be square
    if (rowSpan != columnSpan) return false;
    return rowSpan >= 1 && rowSpan <= 4;
  }
  
  @override
  Widget build(BuildContext context, Map<String, dynamic> config, NowPlayingState state) {
    final shape = config['shape'] as String? ?? 'square';
    final borderRadius = (config['borderRadius'] as num?)?.toDouble() ?? 8.0;
    final showShadow = config['showShadow'] as bool? ?? true;
    final animation = config['animation'] as String? ?? 'none';
    
    final coverArtUri = state.currentSong?.coverArtUri;
    
    // Determine border radius based on shape
    BorderRadius? widgetBorderRadius;
    if (shape == 'circle') {
      widgetBorderRadius = null; // ClipOval will be applied separately
    } else {
      widgetBorderRadius = BorderRadius.circular(borderRadius);
    }
    
    Widget coverWidget = CoverArtWidget(
      coverArtUri: coverArtUri,
      fit: BoxFit.cover,
      borderRadius: widgetBorderRadius,
      placeholder: _buildPlaceholder(context),
      errorWidget: _buildPlaceholder(context),
    );
    
    // Apply shape
    if (shape == 'circle') {
      coverWidget = ClipOval(child: coverWidget);
    } else if (shape == 'rounded' || shape == 'square') {
      // Border radius already applied in CoverArtWidget
      coverWidget = coverWidget;
    }
    
    // Apply shadow
    if (showShadow) {
      coverWidget = Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: coverWidget,
      );
    }
    
    // Apply animation
    if (animation == 'rotate') {
      return _AnimatedRotatingCover(child: coverWidget);
    } else if (animation == 'scale') {
      return _AnimatedScalingCover(child: coverWidget);
    } else if (animation == 'fade') {
      return _AnimatedFadingCover(child: coverWidget);
    }
    
    return coverWidget;
  }
  
  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.music_note,
        size: 48,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _AnimatedRotatingCover extends StatefulWidget {
  final Widget child;
  
  const _AnimatedRotatingCover({required this.child});
  
  @override
  State<_AnimatedRotatingCover> createState() => _AnimatedRotatingCoverState();
}

class _AnimatedRotatingCoverState extends State<_AnimatedRotatingCover>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: widget.child,
    );
  }
}

class _AnimatedScalingCover extends StatefulWidget {
  final Widget child;
  
  const _AnimatedScalingCover({required this.child});
  
  @override
  State<_AnimatedScalingCover> createState() => _AnimatedScalingCoverState();
}

class _AnimatedScalingCoverState extends State<_AnimatedScalingCover>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.95, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: widget.child,
    );
  }
}

class _AnimatedFadingCover extends StatefulWidget {
  final Widget child;
  
  const _AnimatedFadingCover({required this.child});
  
  @override
  State<_AnimatedFadingCover> createState() => _AnimatedFadingCoverState();
}

class _AnimatedFadingCoverState extends State<_AnimatedFadingCover>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: widget.child,
    );
  }
}
