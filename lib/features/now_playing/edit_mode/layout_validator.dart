import '../layout/layout_slot.dart';
import '../layout/layout_preset.dart';

/// Validates component placement in the layout
class LayoutValidator {
  /// Check if a component can be placed at a specific location
  bool canPlaceComponent(
    List<LayoutSlot> currentSlots,
    String componentId,
    int row,
    int column,
    int rowSpan,
    int columnSpan,
  ) {
    // Check bounds
    if (row < 0 || column < 0) return false;
    if (row + rowSpan > NowPlayingLayoutHelper.gridRows) return false;
    if (column + columnSpan > NowPlayingLayoutHelper.gridColumns) return false;

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
    final existingSlot = NowPlayingLayoutHelper.getSlotAt(currentSlots, row, column);
    if (existingSlot != null && existingSlot.allowedComponents.isNotEmpty) {
      if (!existingSlot.allowedComponents.contains(componentId)) {
        return false;
      }
    }

    return true;
  }

  /// Validate entire layout
  bool validateLayout(List<LayoutSlot> slots) {
    // Check for overlapping slots
    for (int i = 0; i < slots.length; i++) {
      for (int j = i + 1; j < slots.length; j++) {
        if (_slotsOverlap(slots[i], slots[j])) {
          return false;
        }
      }
    }

    // Check bounds
    for (final slot in slots) {
      if (slot.row < 0 || slot.column < 0) return false;
      if (slot.row + slot.rowSpan > NowPlayingLayoutHelper.gridRows) return false;
      if (slot.column + slot.columnSpan > NowPlayingLayoutHelper.gridColumns) return false;
    }

    return true;
  }

  bool _slotsOverlap(LayoutSlot slot1, LayoutSlot slot2) {
    return !(
      slot1.row + slot1.rowSpan <= slot2.row ||
      slot2.row + slot2.rowSpan <= slot1.row ||
      slot1.column + slot1.columnSpan <= slot2.column ||
      slot2.column + slot2.columnSpan <= slot1.column
    );
  }
}
