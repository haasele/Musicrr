import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Service for extracting colors from album art and generating dynamic themes
class DynamicColorService {
  /// Extract a full Material 3 ColorScheme from an image
  static Future<ColorScheme> extractColorScheme(
    String? imageUrl, {
    bool isDark = false,
  }) async {
    if (imageUrl == null) {
      return _defaultColorScheme(isDark);
    }

    try {
      final imageProvider = CachedNetworkImageProvider(imageUrl);
      final palette = await PaletteGenerator.fromImageProvider(imageProvider);

      // Use the most vibrant color as seed
      final seedColor = palette.vibrantColor?.color ??
          palette.lightVibrantColor?.color ??
          palette.dominantColor?.color ??
          Colors.blue;

      // Generate Material 3 color scheme
      return ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: isDark ? Brightness.dark : Brightness.light,
      );
    } catch (e) {
      return _defaultColorScheme(isDark);
    }
  }

  /// Extract a single color from an image
  static Future<Color> extractColor(
    String? imageUrl, {
    ColorExtractionMode mode = ColorExtractionMode.vibrant,
  }) async {
    if (imageUrl == null) {
      return Colors.blue;
    }

    try {
      final imageProvider = CachedNetworkImageProvider(imageUrl);
      final palette = await PaletteGenerator.fromImageProvider(imageProvider);

      switch (mode) {
        case ColorExtractionMode.dominant:
          return palette.dominantColor?.color ?? Colors.blue;
        case ColorExtractionMode.vibrant:
          return palette.vibrantColor?.color ?? Colors.blue;
        case ColorExtractionMode.muted:
          return palette.mutedColor?.color ?? Colors.blue;
        case ColorExtractionMode.lightVibrant:
          return palette.lightVibrantColor?.color ?? Colors.blue;
        case ColorExtractionMode.darkVibrant:
          return palette.darkVibrantColor?.color ?? Colors.blue;
      }
    } catch (e) {
      return Colors.blue;
    }
  }

  /// Generate a ThemeData from an extracted color scheme
  static ThemeData generateTheme(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      // Material 3 Expressive: Tonal surfaces
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: colorScheme.surfaceContainerHighest,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static ColorScheme _defaultColorScheme(bool isDark) {
    return ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: isDark ? Brightness.dark : Brightness.light,
    );
  }
}

enum ColorExtractionMode {
  dominant,
  vibrant,
  muted,
  lightVibrant,
  darkVibrant,
}
