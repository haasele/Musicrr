import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// A reusable widget for displaying cover art that handles both file:// and network URIs
class CoverArtWidget extends StatelessWidget {
  final String? coverArtUri;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CoverArtWidget({
    super.key,
    this.coverArtUri,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (coverArtUri == null || coverArtUri!.isEmpty) {
      return _buildPlaceholder(context);
    }

    final uri = coverArtUri!;
    final isFileUri = uri.startsWith('file://');

    Widget imageWidget;
    if (isFileUri) {
      try {
        // Handle file:// URIs - extract the path correctly
        final parsedUri = Uri.parse(uri);
        final filePath = parsedUri.path;
        final file = File(filePath);
        
        // Check if file exists before trying to load it
        if (file.existsSync()) {
          imageWidget = Image.file(
            file,
            fit: fit,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('CoverArtWidget: Error loading file image: $error');
              return _buildErrorWidget(context);
            },
          );
        } else {
          debugPrint('CoverArtWidget: File does not exist: $filePath');
          imageWidget = _buildErrorWidget(context);
        }
      } catch (e) {
        debugPrint('CoverArtWidget: Error parsing file URI: $e');
        imageWidget = _buildErrorWidget(context);
      }
    } else {
      imageWidget = CachedNetworkImage(
        imageUrl: uri,
        fit: fit,
        placeholder: (context, url) => _buildPlaceholder(context),
        errorWidget: (context, url, error) => _buildErrorWidget(context),
      );
    }

    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    if (width != null || height != null) {
      return SizedBox(
        width: width,
        height: height,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildPlaceholder(BuildContext context) {
    if (placeholder != null) return placeholder!;
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: borderRadius,
      ),
      child: Icon(
        Icons.music_note,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: (width != null && height != null) 
            ? (width! < height! ? width! * 0.4 : height! * 0.4)
            : 48,
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    if (errorWidget != null) return errorWidget!;
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: borderRadius,
      ),
      child: Icon(
        Icons.music_note,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: (width != null && height != null) 
            ? (width! < height! ? width! * 0.4 : height! * 0.4)
            : 48,
      ),
    );
  }
}
