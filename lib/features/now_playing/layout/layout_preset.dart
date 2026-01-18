import 'layout_slot.dart';

/// Scope for preset application
enum PresetScope {
  global,      // Applies to all sources
  perProvider, // Applies to specific provider
  perAlbum,    // Applies to specific album
}

/// Background type
enum BackgroundType {
  solid,
  dynamic,      // From album art
  gradient,     // From album art
  animatedGradient,
  visualizer,
}

/// Background configuration
class BackgroundConfig {
  final BackgroundType type;
  final int? colorValue; // For solid color (ARGB int)
  final String? extractionMode; // For dynamic color
  final List<int>? gradientColorValues; // For gradient (ARGB ints)
  final String? gradientDirection; // For gradient
  final Map<String, dynamic>? animationConfig; // For animated gradient
  
  const BackgroundConfig({
    required this.type,
    this.colorValue,
    this.extractionMode,
    this.gradientColorValues,
    this.gradientDirection,
    this.animationConfig,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'color': colorValue,
      'extractionMode': extractionMode,
      'gradientColors': gradientColorValues,
      'direction': gradientDirection,
      'animation': animationConfig,
    };
  }
  
  factory BackgroundConfig.fromJson(Map<String, dynamic> json) {
    return BackgroundConfig(
      type: BackgroundType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => BackgroundType.solid,
      ),
      colorValue: json['color'] as int?,
      extractionMode: json['extractionMode'] as String?,
      gradientColorValues: json['gradientColors'] != null
          ? List<int>.from(json['gradientColors'] as List)
          : null,
      gradientDirection: json['direction'] as String?,
      animationConfig: json['animation'] as Map<String, dynamic>?,
    );
  }
}

/// Now Playing layout preset
class NowPlayingLayout {
  final String id;
  final String name;
  final String? description;
  final List<LayoutSlot> slots;
  final BackgroundConfig background;
  final Map<String, dynamic>? themeOverrides;
  final DateTime createdAt;
  final DateTime? lastModified;
  final PresetScope scope;
  final String? sourceId; // Provider ID or album ID
  
  const NowPlayingLayout({
    required this.id,
    required this.name,
    this.description,
    required this.slots,
    required this.background,
    this.themeOverrides,
    required this.createdAt,
    this.lastModified,
    required this.scope,
    this.sourceId,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'slots': slots.map((s) => s.toJson()).toList(),
      'background': background.toJson(),
      'themeOverrides': themeOverrides,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified?.toIso8601String(),
      'scope': scope.name,
      'sourceId': sourceId,
    };
  }
  
  factory NowPlayingLayout.fromJson(Map<String, dynamic> json) {
    return NowPlayingLayout(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      slots: (json['slots'] as List)
          .map((s) => LayoutSlot.fromJson(s as Map<String, dynamic>))
          .toList(),
      background: BackgroundConfig.fromJson(json['background'] as Map<String, dynamic>),
      themeOverrides: json['themeOverrides'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'] as String)
          : null,
      scope: PresetScope.values.firstWhere(
        (e) => e.name == json['scope'],
        orElse: () => PresetScope.global,
      ),
      sourceId: json['sourceId'] as String?,
    );
  }
}

/// Helper class for layout operations
class NowPlayingLayoutHelper {
  static const int gridRows = 6;
  static const int gridColumns = 4;
  static const double slotAspectRatio = 1.0;
  
  /// Get slot at specific grid position
  static LayoutSlot? getSlotAt(List<LayoutSlot> slots, int row, int column) {
    for (final slot in slots) {
      if (slot.row <= row && 
          row < slot.row + slot.rowSpan &&
          slot.column <= column &&
          column < slot.column + slot.columnSpan) {
        return slot;
      }
    }
    return null;
  }
  
  /// Check if a slot area is available
  static bool isSlotAreaAvailable(
    List<LayoutSlot> slots,
    int row,
    int column,
    int rowSpan,
    int columnSpan,
  ) {
    // Check bounds
    if (row < 0 || column < 0 ||
        row + rowSpan > gridRows ||
        column + columnSpan > gridColumns) {
      return false;
    }
    
    // Check for overlaps
    for (final slot in slots) {
      if (slot.componentId == null) continue; // Empty slots don't block
      
      final slotRowEnd = slot.row + slot.rowSpan;
      final slotColumnEnd = slot.column + slot.columnSpan;
      final newRowEnd = row + rowSpan;
      final newColumnEnd = column + columnSpan;
      
      // Check if rectangles overlap
      if (!(row >= slotRowEnd || newRowEnd <= slot.row ||
            column >= slotColumnEnd || newColumnEnd <= slot.column)) {
        return false; // Overlap detected
      }
    }
    
    return true;
  }
  
  /// Create empty layout grid
  static List<LayoutSlot> createEmptyLayout() {
    final slots = <LayoutSlot>[];
    for (int row = 0; row < gridRows; row++) {
      for (int col = 0; col < gridColumns; col++) {
        slots.add(LayoutSlot(
          row: row,
          column: col,
          rowSpan: 1,
          columnSpan: 1,
        ));
      }
    }
    return slots;
  }
}
