import 'package:flutter/material.dart';
import '../layout/layout_engine.dart';

/// Base interface for Now Playing components
abstract class NowPlayingComponent {
  final String id;
  final String type;
  final Map<String, dynamic> defaultConfig;
  
  const NowPlayingComponent({
    required this.id,
    required this.type,
    this.defaultConfig = const {},
  });
  
  /// Build the component widget
  Widget build(BuildContext context, Map<String, dynamic> config, NowPlayingState state);
  
  /// Get supported size options for this component
  List<SizeOption> getSupportedSizes();
  
  /// Check if component can be resized to given dimensions
  bool canResizeTo(int rowSpan, int columnSpan);
  
  /// Build configuration panel for this component
  Widget? buildConfigPanel(
    BuildContext context,
    Map<String, dynamic> currentConfig,
    ValueChanged<Map<String, dynamic>> onConfigChanged,
  ) {
    return null; // Default: no configuration panel
  }
  
  /// Get default configuration
  Map<String, dynamic> getDefaultConfig() => defaultConfig;
}

/// Size option for components
class SizeOption {
  final int rowSpan;
  final int columnSpan;
  final String label;
  
  const SizeOption({
    required this.rowSpan,
    required this.columnSpan,
    required this.label,
  });
}
