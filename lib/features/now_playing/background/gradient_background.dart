import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:cached_network_image/cached_network_image.dart';

class GradientBackground extends StatefulWidget {
  final String? imageUrl;
  final Widget child;
  final GradientDirection direction;
  final int colorCount;
  
  const GradientBackground({
    super.key,
    this.imageUrl,
    required this.child,
    this.direction = GradientDirection.topToBottom,
    this.colorCount = 2,
  });
  
  @override
  State<GradientBackground> createState() => _GradientBackgroundState();
}

enum GradientDirection {
  topToBottom,
  bottomToTop,
  leftToRight,
  rightToLeft,
  diagonalTopLeft,
  diagonalTopRight,
}

class _GradientBackgroundState extends State<GradientBackground> {
  List<Color>? _gradientColors;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    if (widget.imageUrl != null) {
      _extractColors();
    } else {
      _isLoading = false;
    }
  }
  
  @override
  void didUpdateWidget(GradientBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _extractColors();
    }
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
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: Theme.of(context).colorScheme.surface,
        child: widget.child,
      );
    }
    
    final colors = _gradientColors ?? [
      Theme.of(context).colorScheme.surface,
      Theme.of(context).colorScheme.surfaceVariant,
    ];
    
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
  }
}
