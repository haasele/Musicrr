import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DynamicColorBackground extends StatefulWidget {
  final String? imageUrl;
  final Widget child;
  final ColorExtractionMode extractionMode;
  
  const DynamicColorBackground({
    super.key,
    this.imageUrl,
    required this.child,
    this.extractionMode = ColorExtractionMode.dominant,
  });
  
  @override
  State<DynamicColorBackground> createState() => _DynamicColorBackgroundState();
}

enum ColorExtractionMode {
  dominant,
  vibrant,
  muted,
  lightVibrant,
  darkVibrant,
}

class _DynamicColorBackgroundState extends State<DynamicColorBackground> {
  Color? _extractedColor;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    if (widget.imageUrl != null) {
      _extractColor();
    } else {
      _isLoading = false;
    }
  }
  
  @override
  void didUpdateWidget(DynamicColorBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _extractColor();
    }
  }
  
  Future<void> _extractColor() async {
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
      
      Color? extractedColor;
      switch (widget.extractionMode) {
        case ColorExtractionMode.dominant:
          extractedColor = palette.dominantColor?.color;
          break;
        case ColorExtractionMode.vibrant:
          extractedColor = palette.vibrantColor?.color;
          break;
        case ColorExtractionMode.muted:
          extractedColor = palette.mutedColor?.color;
          break;
        case ColorExtractionMode.lightVibrant:
          extractedColor = palette.lightVibrantColor?.color;
          break;
        case ColorExtractionMode.darkVibrant:
          extractedColor = palette.darkVibrantColor?.color;
          break;
      }
      
      setState(() {
        _extractedColor = extractedColor ?? Colors.grey.shade800;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _extractedColor = Colors.grey.shade800;
        _isLoading = false;
      });
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
    
    return Container(
      color: _extractedColor ?? Theme.of(context).colorScheme.surface,
      child: widget.child,
    );
  }
}
