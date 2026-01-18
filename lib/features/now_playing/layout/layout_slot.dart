import 'package:flutter/material.dart';

/// Represents a slot in the Now Playing layout grid
class LayoutSlot {
  final int row;
  final int column;
  final int rowSpan;
  final int columnSpan;
  final String? componentId; // null if empty
  final Map<String, dynamic> componentConfig;
  
  // Constraints
  final List<String> allowedComponents;
  final SizeConstraints? sizeConstraints;
  
  // Visual properties
  final EdgeInsets padding;
  final BorderRadius? borderRadius;
  
  const LayoutSlot({
    required this.row,
    required this.column,
    this.rowSpan = 1,
    this.columnSpan = 1,
    this.componentId,
    this.componentConfig = const {},
    this.allowedComponents = const [],
    this.sizeConstraints,
    this.padding = EdgeInsets.zero,
    this.borderRadius,
  });
  
  LayoutSlot copyWith({
    int? row,
    int? column,
    int? rowSpan,
    int? columnSpan,
    String? componentId,
    Map<String, dynamic>? componentConfig,
    List<String>? allowedComponents,
    SizeConstraints? sizeConstraints,
    EdgeInsets? padding,
    BorderRadius? borderRadius,
  }) {
    return LayoutSlot(
      row: row ?? this.row,
      column: column ?? this.column,
      rowSpan: rowSpan ?? this.rowSpan,
      columnSpan: columnSpan ?? this.columnSpan,
      componentId: componentId ?? this.componentId,
      componentConfig: componentConfig ?? this.componentConfig,
      allowedComponents: allowedComponents ?? this.allowedComponents,
      sizeConstraints: sizeConstraints ?? this.sizeConstraints,
      padding: padding ?? this.padding,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }
  
  bool get isEmpty => componentId == null;
  
  Map<String, dynamic> toJson() {
    return {
      'row': row,
      'column': column,
      'rowSpan': rowSpan,
      'columnSpan': columnSpan,
      'componentId': componentId,
      'componentConfig': componentConfig,
      'allowedComponents': allowedComponents,
      'padding': {
        'left': padding.left,
        'top': padding.top,
        'right': padding.right,
        'bottom': padding.bottom,
      },
    };
  }
  
  factory LayoutSlot.fromJson(Map<String, dynamic> json) {
    final paddingData = json['padding'] as Map<String, dynamic>? ?? {};
    return LayoutSlot(
      row: json['row'] as int,
      column: json['column'] as int,
      rowSpan: json['rowSpan'] as int? ?? 1,
      columnSpan: json['columnSpan'] as int? ?? 1,
      componentId: json['componentId'] as String?,
      componentConfig: Map<String, dynamic>.from(json['componentConfig'] as Map? ?? {}),
      allowedComponents: List<String>.from(json['allowedComponents'] as List? ?? []),
      padding: EdgeInsets.only(
        left: (paddingData['left'] as num?)?.toDouble() ?? 0,
        top: (paddingData['top'] as num?)?.toDouble() ?? 0,
        right: (paddingData['right'] as num?)?.toDouble() ?? 0,
        bottom: (paddingData['bottom'] as num?)?.toDouble() ?? 0,
      ),
    );
  }
}

/// Size constraints for a component
class SizeConstraints {
  final int? minRowSpan;
  final int? maxRowSpan;
  final int? minColumnSpan;
  final int? maxColumnSpan;
  
  const SizeConstraints({
    this.minRowSpan,
    this.maxRowSpan,
    this.minColumnSpan,
    this.maxColumnSpan,
  });
  
  bool isValid(int rowSpan, int columnSpan) {
    if (minRowSpan != null && rowSpan < minRowSpan!) return false;
    if (maxRowSpan != null && rowSpan > maxRowSpan!) return false;
    if (minColumnSpan != null && columnSpan < minColumnSpan!) return false;
    if (maxColumnSpan != null && columnSpan > maxColumnSpan!) return false;
    return true;
  }
}
