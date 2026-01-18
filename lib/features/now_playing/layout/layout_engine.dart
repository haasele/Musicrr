import 'package:flutter/material.dart';
import 'layout_slot.dart';
import 'layout_preset.dart';
import '../../../core/models/song.dart';
import '../../../core/audio/audio_engine.dart';

/// Component registry for Now Playing components
class ComponentRegistry {
  static final Map<String, NowPlayingComponentFactory> _factories = {};
  
  static void register(String componentId, NowPlayingComponentFactory factory) {
    _factories[componentId] = factory;
  }
  
  static NowPlayingComponentFactory? getFactory(String componentId) {
    return _factories[componentId];
  }
  
  static List<String> get registeredComponentIds => _factories.keys.toList();
}

/// Factory interface for creating components
typedef NowPlayingComponentFactory = Widget Function(
  BuildContext context,
  Map<String, dynamic> config,
  NowPlayingState state,
);

/// State passed to components
class NowPlayingState {
  final PlaybackState? playbackState;
  final Song? currentSong;
  final int positionMs;
  final int durationMs;
  final double volume;
  final void Function(int positionMs)? onSeek;
  
  const NowPlayingState({
    this.playbackState,
    this.currentSong,
    this.positionMs = 0,
    this.durationMs = 0,
    this.volume = 1.0,
    this.onSeek,
  });
}

/// Layout engine for rendering Now Playing screen
class NowPlayingLayoutEngine {
  /// Build the layout from a preset
  Widget buildLayout(
    BuildContext context,
    NowPlayingLayout layout,
    NowPlayingState state,
  ) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: NowPlayingLayoutHelper.gridColumns,
        childAspectRatio: NowPlayingLayoutHelper.slotAspectRatio,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: NowPlayingLayoutHelper.gridRows * NowPlayingLayoutHelper.gridColumns,
      itemBuilder: (context, index) {
        final row = index ~/ NowPlayingLayoutHelper.gridColumns;
        final column = index % NowPlayingLayoutHelper.gridColumns;
        return _buildSlot(context, layout.slots, row, column, state);
      },
    );
  }
  
  Widget _buildSlot(
    BuildContext context,
    List<LayoutSlot> slots,
    int row,
    int column,
    NowPlayingState state,
  ) {
    final slot = NowPlayingLayoutHelper.getSlotAt(slots, row, column);
    
    // Only render if this is the top-left corner of the slot
    if (slot != null && slot.row == row && slot.column == column) {
      return _buildSlotContent(context, slot, state);
    }
    
    // Empty slot or part of a larger slot
    if (slot == null) {
      return Container(); // Empty slot
    }
    
    // This cell is part of a larger slot, return empty
    return const SizedBox.shrink();
  }
  
  Widget _buildSlotContent(
    BuildContext context,
    LayoutSlot slot,
    NowPlayingState state,
  ) {
    if (slot.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      );
    }
    
    final factory = ComponentRegistry.getFactory(slot.componentId!);
    if (factory == null) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: slot.borderRadius,
        ),
        child: Center(
          child: Text(
            'Unknown component: ${slot.componentId}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }
    
    return Container(
      padding: slot.padding,
      decoration: BoxDecoration(
        borderRadius: slot.borderRadius,
      ),
      child: factory(context, slot.componentConfig, state),
    );
  }
  
  /// Validate if a component can be placed at a location
  bool canPlaceComponent(
    List<LayoutSlot> currentSlots,
    String componentId,
    int row,
    int column,
    int rowSpan,
    int columnSpan,
  ) {
    // Check if area is available
    if (!NowPlayingLayoutHelper.isSlotAreaAvailable(
      currentSlots,
      row,
      column,
      rowSpan,
      columnSpan,
    )) {
      return false;
    }
    
    // Check component constraints (if any)
    final slot = NowPlayingLayoutHelper.getSlotAt(currentSlots, row, column);
    if (slot != null && slot.allowedComponents.isNotEmpty) {
      if (!slot.allowedComponents.contains(componentId)) {
        return false;
      }
    }
    
    return true;
  }
}
