import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AnimatedGradientBackground extends StatefulWidget {
  final String? imageUrl;
  final Widget child;
  final GradientDirection direction;
  final int colorCount;
  final Duration animationDuration;
  final Curve animationCurve;
  
  const AnimatedGradientBackground({
    super.key,
    this.imageUrl,
    required this.child,
    this.direction = GradientDirection.topToBottom,
    this.colorCount = 2,
    this.animationDuration = const Duration(seconds: 3),
    this.animationCurve = Curves.easeInOut,
  });
  
  @override
  State<AnimatedGradientBackground> createState() => _AnimatedGradientBackgroundState();
}

enum GradientDirection {
  topToBottom,
  bottomToTop,
  leftToRight,
  rightToLeft,
  diagonalTopLeft,
  diagonalTopRight,
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  List<Color>? _gradientColors;
  bool _isLoading = true;
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.animationCurve,
    );
    
    if (widget.imageUrl != null) {
      _extractColors();
    } else {
      _isLoading = false;
    }
  }
  
  @override
  void didUpdateWidget(AnimatedGradientBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _extractColors();
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  Future<void> _extractColors() async {
    if (widget.imageUrl == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final imageProvider = CachedNetworkImageProvider(widget.imageUrl!);
      final palette = await PaletteGenerator.fromImageProvider(imageProvider);
      
      final colors = <Color>[];
      
      // Extract colors based on count
      if (palette.dominantColor != null) {
        colors.add(palette.dominantColor!.color);
      }
      if (widget.colorCount >= 2 && palette.vibrantColor != null) {
        colors.add(palette.vibrantColor!.color);
      }
      if (widget.colorCount >= 3 && palette.mutedColor != null) {
        colors.add(palette.mutedColor!.color);
      }
      if (widget.colorCount >= 4 && palette.lightVibrantColor != null) {
        colors.add(palette.lightVibrantColor!.color);
      }
      if (widget.colorCount >= 5 && palette.darkVibrantColor != null) {
        colors.add(palette.darkVibrantColor!.color);
      }
      
      // Fill remaining slots if needed
      while (colors.length < widget.colorCount && colors.isNotEmpty) {
        colors.add(colors.last);
      }
      
      // Fallback if no colors extracted
      if (colors.isEmpty) {
        colors.add(Colors.grey.shade800);
        colors.add(Colors.grey.shade900);
      }
      
      setState(() {
        _gradientColors = colors;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _gradientColors = [Colors.grey.shade800, Colors.grey.shade900];
        _isLoading = false;
      });
    }
  }
  
  AlignmentGeometry _getAlignment() {
    switch (widget.direction) {
      case GradientDirection.topToBottom:
        return Alignment.topCenter;
      case GradientDirection.bottomToTop:
        return Alignment.bottomCenter;
      case GradientDirection.leftToRight:
        return Alignment.centerLeft;
      case GradientDirection.rightToLeft:
        return Alignment.centerRight;
      case GradientDirection.diagonalTopLeft:
        return Alignment.topLeft;
      case GradientDirection.diagonalTopRight:
        return Alignment.topRight;
    }
  }
  
  AlignmentGeometry _getEndAlignment() {
    switch (widget.direction) {
      case GradientDirection.topToBottom:
        return Alignment.bottomCenter;
      case GradientDirection.bottomToTop:
        return Alignment.topCenter;
      case GradientDirection.leftToRight:
        return Alignment.centerRight;
      case GradientDirection.rightToLeft:
        return Alignment.centerLeft;
      case GradientDirection.diagonalTopLeft:
        return Alignment.bottomRight;
      case GradientDirection.diagonalTopRight:
        return Alignment.bottomLeft;
    }
  }
  
  List<Color> _getAnimatedColors() {
    if (_gradientColors == null || _gradientColors!.isEmpty) {
      return [Colors.grey.shade800, Colors.grey.shade900];
    }
    
    final baseColors = _gradientColors!;
    final animatedColors = <Color>[];
    
    for (int i = 0; i < baseColors.length - 1; i++) {
      final color1 = baseColors[i];
      final color2 = baseColors[i + 1];
      
      // Interpolate between colors based on animation
      final animatedColor = Color.lerp(color1, color2, _animation.value)!;
      animatedColors.add(animatedColor);
    }
    
    // Add last color
    if (baseColors.isNotEmpty) {
      animatedColors.add(baseColors.last);
    }
    
    return animatedColors.isNotEmpty ? animatedColors : baseColors;
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: Theme.of(context).colorScheme.surface,
        child: widget.child,
      );
    }
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final colors = _getAnimatedColors();
        
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: _getAlignment(),
              end: _getEndAlignment(),
              colors: colors,
            ),
          ),
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}
