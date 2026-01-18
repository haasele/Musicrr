import 'package:uuid/uuid.dart';
import '../layout/layout_preset.dart';
import '../layout/layout_slot.dart';

class BuiltinPresets {
  static const _uuid = Uuid();
  
  /// Create default presets
  static List<NowPlayingLayout> createDefaultPresets() {
    return [
      _createClassicPreset(),
      _createMinimalPreset(),
      _createVisualizerFocusPreset(),
      _createLyricsFocusPreset(),
      _createCompactPreset(),
    ];
  }
  
  /// Classic preset: Large cover art, track info, progress, controls
  static NowPlayingLayout _createClassicPreset() {
    return NowPlayingLayout(
      id: _uuid.v4(),
      name: 'Classic',
      description: 'Large cover art with track info and controls',
      slots: [
        // Cover art (center, 3x3)
        LayoutSlot(
          row: 0,
          column: 0,
          rowSpan: 3,
          columnSpan: 4,
          componentId: 'cover_art',
          componentConfig: {
            'shape': 'rounded',
            'borderRadius': 12.0,
            'showShadow': true,
            'animation': 'none',
          },
        ),
        // Track info (below cover, 1x4)
        LayoutSlot(
          row: 3,
          column: 0,
          rowSpan: 1,
          columnSpan: 4,
          componentId: 'track_info',
          componentConfig: {
            'layout': 'stacked',
            'showTitle': true,
            'showArtist': true,
            'showAlbum': true,
            'textAlign': 'center',
          },
        ),
        // Progress slider (1x4)
        LayoutSlot(
          row: 4,
          column: 0,
          rowSpan: 1,
          columnSpan: 4,
          componentId: 'progress_slider',
          componentConfig: {
            'variant': 'material3',
            'showTimeLabels': true,
            'showThumb': true,
          },
        ),
        // Controls (1x4)
        LayoutSlot(
          row: 5,
          column: 0,
          rowSpan: 1,
          columnSpan: 4,
          componentId: 'control_buttons',
          componentConfig: {
            'layout': 'horizontal',
            'showShuffle': true,
            'showRepeat': true,
            'buttonSize': 'medium',
          },
        ),
      ],
      background: BackgroundConfig(
        type: BackgroundType.dynamic,
        extractionMode: 'dominant',
      ),
      createdAt: DateTime.now(),
      scope: PresetScope.global,
    );
  }
  
  /// Minimal preset: Small cover, compact layout
  static NowPlayingLayout _createMinimalPreset() {
    return NowPlayingLayout(
      id: _uuid.v4(),
      name: 'Minimal',
      description: 'Compact layout with small cover art',
      slots: [
        // Cover art (top-left, 2x2)
        LayoutSlot(
          row: 0,
          column: 0,
          rowSpan: 2,
          columnSpan: 2,
          componentId: 'cover_art',
          componentConfig: {
            'shape': 'square',
            'borderRadius': 8.0,
            'showShadow': false,
            'animation': 'none',
          },
        ),
        // Track info (top-right, 2x2)
        LayoutSlot(
          row: 0,
          column: 2,
          rowSpan: 2,
          columnSpan: 2,
          componentId: 'track_info',
          componentConfig: {
            'layout': 'stacked',
            'showTitle': true,
            'showArtist': true,
            'showAlbum': false,
            'textAlign': 'left',
          },
        ),
        // Progress slider (1x4)
        LayoutSlot(
          row: 2,
          column: 0,
          rowSpan: 1,
          columnSpan: 4,
          componentId: 'progress_slider',
          componentConfig: {
            'variant': 'simple',
            'showTimeLabels': true,
            'showThumb': true,
          },
        ),
        // Controls (1x4)
        LayoutSlot(
          row: 3,
          column: 0,
          rowSpan: 1,
          columnSpan: 4,
          componentId: 'control_buttons',
          componentConfig: {
            'layout': 'horizontal',
            'showShuffle': false,
            'showRepeat': false,
            'buttonSize': 'medium',
          },
        ),
      ],
      background: BackgroundConfig(
        type: BackgroundType.solid,
        colorValue: 0xFF000000, // Black
      ),
      createdAt: DateTime.now(),
      scope: PresetScope.global,
    );
  }
  
  /// Visualizer Focus: Full-screen visualizer with overlay controls
  static NowPlayingLayout _createVisualizerFocusPreset() {
    return NowPlayingLayout(
      id: _uuid.v4(),
      name: 'Visualizer Focus',
      description: 'Full-screen visualizer with overlay controls',
      slots: [
        // Visualizer (full screen, 4x4)
        LayoutSlot(
          row: 0,
          column: 0,
          rowSpan: 4,
          columnSpan: 4,
          componentId: 'visualizer',
          componentConfig: {
            'presetPath': null,
            'showControls': false,
          },
        ),
        // Cover art (overlay, small, 1x1)
        LayoutSlot(
          row: 0,
          column: 0,
          rowSpan: 1,
          columnSpan: 1,
          componentId: 'cover_art',
          componentConfig: {
            'shape': 'circle',
            'borderRadius': 0.0,
            'showShadow': true,
            'animation': 'none',
          },
        ),
        // Track info (overlay, bottom, 1x4)
        LayoutSlot(
          row: 3,
          column: 0,
          rowSpan: 1,
          columnSpan: 4,
          componentId: 'track_info',
          componentConfig: {
            'layout': 'inline',
            'showTitle': true,
            'showArtist': true,
            'showAlbum': false,
            'textAlign': 'center',
          },
        ),
        // Progress slider (overlay, 1x4)
        LayoutSlot(
          row: 4,
          column: 0,
          rowSpan: 1,
          columnSpan: 4,
          componentId: 'progress_slider',
          componentConfig: {
            'variant': 'material3',
            'showTimeLabels': true,
            'showThumb': true,
          },
        ),
        // Controls (overlay, 1x4)
        LayoutSlot(
          row: 5,
          column: 0,
          rowSpan: 1,
          columnSpan: 4,
          componentId: 'control_buttons',
          componentConfig: {
            'layout': 'horizontal',
            'showShuffle': true,
            'showRepeat': true,
            'buttonSize': 'medium',
          },
        ),
      ],
      background: BackgroundConfig(
        type: BackgroundType.visualizer,
      ),
      createdAt: DateTime.now(),
      scope: PresetScope.global,
    );
  }
  
  /// Lyrics Focus: Large lyrics display
  static NowPlayingLayout _createLyricsFocusPreset() {
    return NowPlayingLayout(
      id: _uuid.v4(),
      name: 'Lyrics Focus',
      description: 'Large lyrics display with minimal controls',
      slots: [
        // Cover art (small, top, 1x1)
        LayoutSlot(
          row: 0,
          column: 0,
          rowSpan: 1,
          columnSpan: 1,
          componentId: 'cover_art',
          componentConfig: {
            'shape': 'rounded',
            'borderRadius': 8.0,
            'showShadow': false,
            'animation': 'none',
          },
        ),
        // Track info (top, 1x3)
        LayoutSlot(
          row: 0,
          column: 1,
          rowSpan: 1,
          columnSpan: 3,
          componentId: 'track_info',
          componentConfig: {
            'layout': 'compact',
            'showTitle': true,
            'showArtist': true,
            'showAlbum': false,
            'textAlign': 'left',
          },
        ),
        // Lyrics (large, 3x4)
        LayoutSlot(
          row: 1,
          column: 0,
          rowSpan: 3,
          columnSpan: 4,
          componentId: 'lyrics',
          componentConfig: {
            'mode': 'fullscreen',
            'autoScroll': true,
            'fontSize': 18.0,
            'textAlign': 'center',
          },
        ),
        // Progress slider (1x4)
        LayoutSlot(
          row: 4,
          column: 0,
          rowSpan: 1,
          columnSpan: 4,
          componentId: 'progress_slider',
          componentConfig: {
            'variant': 'material3',
            'showTimeLabels': true,
            'showThumb': true,
          },
        ),
        // Controls (1x4)
        LayoutSlot(
          row: 5,
          column: 0,
          rowSpan: 1,
          columnSpan: 4,
          componentId: 'control_buttons',
          componentConfig: {
            'layout': 'horizontal',
            'showShuffle': false,
            'showRepeat': false,
            'buttonSize': 'medium',
          },
        ),
      ],
      background: BackgroundConfig(
        type: BackgroundType.gradient,
        gradientColorValues: null, // Will be extracted from album art
        gradientDirection: 'topToBottom',
      ),
      createdAt: DateTime.now(),
      scope: PresetScope.global,
    );
  }
  
  /// Compact: Horizontal layout
  static NowPlayingLayout _createCompactPreset() {
    return NowPlayingLayout(
      id: _uuid.v4(),
      name: 'Compact',
      description: 'Horizontal compact layout',
      slots: [
        // Cover art (left, 2x2)
        LayoutSlot(
          row: 0,
          column: 0,
          rowSpan: 2,
          columnSpan: 2,
          componentId: 'cover_art',
          componentConfig: {
            'shape': 'square',
            'borderRadius': 4.0,
            'showShadow': false,
            'animation': 'none',
          },
        ),
        // Track info (center, 2x2)
        LayoutSlot(
          row: 0,
          column: 2,
          rowSpan: 2,
          columnSpan: 2,
          componentId: 'track_info',
          componentConfig: {
            'layout': 'compact',
            'showTitle': true,
            'showArtist': true,
            'showAlbum': false,
            'textAlign': 'left',
          },
        ),
        // Progress slider (inline, 1x4)
        LayoutSlot(
          row: 2,
          column: 0,
          rowSpan: 1,
          columnSpan: 4,
          componentId: 'progress_slider',
          componentConfig: {
            'variant': 'simple',
            'showTimeLabels': false,
            'showThumb': true,
          },
        ),
        // Controls (right, 2x2)
        LayoutSlot(
          row: 3,
          column: 2,
          rowSpan: 2,
          columnSpan: 2,
          componentId: 'control_buttons',
          componentConfig: {
            'layout': 'grid',
            'showShuffle': false,
            'showRepeat': false,
            'buttonSize': 'small',
          },
        ),
      ],
      background: BackgroundConfig(
        type: BackgroundType.solid,
        colorValue: 0xFF121212, // Dark gray
      ),
      createdAt: DateTime.now(),
      scope: PresetScope.global,
    );
  }
}
