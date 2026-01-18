import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../layout/layout_slot.dart';
import '../layout/layout_preset.dart';
import '../layout/layout_engine.dart';
import '../components/now_playing_component.dart';
import '../components/progress_slider_component.dart';
import '../components/cover_art_component.dart';
import '../components/control_buttons_component.dart';
import '../components/track_info_component.dart';
import '../components/visualizer_component.dart';
import '../components/lyrics_component.dart';
import '../../../core/storage/now_playing_preset_repository.dart';
import '../../../core/audio/audio_engine.dart';
import 'component_library_panel.dart';
import 'layout_validator.dart';

class EditModeScreen extends ConsumerStatefulWidget {
  final NowPlayingLayout initialLayout;

  const EditModeScreen({
    super.key,
    required this.initialLayout,
  });

  @override
  ConsumerState<EditModeScreen> createState() => _EditModeScreenState();
}

class _EditModeScreenState extends ConsumerState<EditModeScreen> {
  late List<LayoutSlot> _slots;
  final LayoutValidator _validator = LayoutValidator();
  bool _showComponentLibrary = false;

  @override
  void initState() {
    super.initState();
    _slots = List.from(widget.initialLayout.slots);
  }
  
  NowPlayingState get _mockState {
    final playbackStateModel = ref.read(playbackStateProvider).value;
    return NowPlayingState(
      playbackState: playbackStateModel?.state,
      currentSong: playbackStateModel?.currentSong,
      positionMs: playbackStateModel?.positionMs ?? 0,
      durationMs: playbackStateModel?.durationMs ?? 0,
      volume: playbackStateModel?.volume ?? 1.0,
    );
  }

  void _addComponent(String componentId, int row, int column) {
    if (!_validator.canPlaceComponent(_slots, componentId, row, column, 1, 1)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot place component here')),
      );
      return;
    }

    setState(() {
      // Remove any existing slot at this position
      _slots.removeWhere((s) => s.row == row && s.column == column);
      
      // Add new slot
      _slots.add(LayoutSlot(
        row: row,
        column: column,
        rowSpan: 1,
        columnSpan: 1,
        componentId: componentId,
        componentConfig: {},
      ));
    });
  }

  void _removeComponent(int row, int column) {
    setState(() {
      _slots.removeWhere((s) => s.row == row && s.column == column);
    });
  }


  Future<void> _saveLayout() async {
    final nameController = TextEditingController(text: widget.initialLayout.name);
    final descriptionController = TextEditingController(text: widget.initialLayout.description ?? '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Layout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'My Custom Layout',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repository = ref.read(nowPlayingPresetRepositoryProvider);
      final updatedLayout = NowPlayingLayout(
        id: widget.initialLayout.id,
        name: nameController.text,
        description: descriptionController.text.isEmpty ? null : descriptionController.text,
        slots: _slots,
        background: widget.initialLayout.background,
        themeOverrides: widget.initialLayout.themeOverrides,
        createdAt: widget.initialLayout.createdAt,
        lastModified: DateTime.now(),
        scope: widget.initialLayout.scope,
        sourceId: widget.initialLayout.sourceId,
      );

      await repository.savePreset(updatedLayout);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Layout saved')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving layout: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Layout'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('How to Edit Layout'),
                  content: const SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('1. Tap the components icon (☰) to open the component library'),
                        SizedBox(height: 8),
                        Text('2. Drag components from the library to empty slots'),
                        SizedBox(height: 8),
                        Text('3. Long-press existing components to move them'),
                        SizedBox(height: 8),
                        Text('4. Tap the X button to remove a component'),
                        SizedBox(height: 8),
                        Text('5. Tap Save when done'),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Help',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveLayout,
            tooltip: 'Save layout',
          ),
          IconButton(
            icon: Icon(_showComponentLibrary ? Icons.close : Icons.apps),
            onPressed: () {
              setState(() {
                _showComponentLibrary = !_showComponentLibrary;
              });
            },
            tooltip: _showComponentLibrary ? 'Hide component library' : 'Show component library',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Layout grid
          _buildEditGrid(),

          // Component library panel (overlay)
          if (_showComponentLibrary)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ComponentLibraryPanel(
                onComponentSelected: (componentId) {
                  // Component selected - can be used for future features
                  // The drag and drop functionality is handled by Draggable widgets
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEditGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
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
        return _buildEditableSlot(row, column);
      },
    );
  }

  Widget _buildEditableSlot(int row, int column) {
    final slot = NowPlayingLayoutHelper.getSlotAt(_slots, row, column);
    
    // Only render if this is the top-left corner of the slot
    if (slot != null && slot.row == row && slot.column == column) {
      return _buildSlotWithComponent(slot, row, column);
    }
    
    // Empty slot or part of a larger slot
    if (slot == null) {
      return _buildEmptySlot(row, column);
    }
    
    // This cell is part of a larger slot
    return const SizedBox.shrink();
  }

  Widget _buildSlotWithComponent(LayoutSlot slot, int row, int column) {
    return DragTarget<String>(
      onAccept: (componentId) {
        _addComponent(componentId, row, column);
      },
      builder: (context, candidateData, rejectedData) {
        final isTargeted = candidateData.isNotEmpty;
        return LongPressDraggable<LayoutSlot>(
          data: slot,
          feedback: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getComponentIcon(slot.componentId ?? ''),
                      size: 32,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getComponentName(slot.componentId ?? ''),
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isTargeted
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).dividerColor,
                width: isTargeted ? 3 : 2,
              ),
              borderRadius: slot.borderRadius ?? BorderRadius.circular(8),
              color: isTargeted
                  ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                  : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
            ),
            child: InkWell(
              onTap: () => _showComponentConfig(context, slot),
              child: Stack(
                children: [
                  // Component preview
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: _buildComponentPreview(slot),
                  ),
                // Remove button
                Positioned(
                  top: 2,
                  right: 2,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _removeComponent(row, column),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                ),
                // Drag handle
                Positioned(
                  top: 2,
                  left: 2,
                  child: Icon(
                    Icons.drag_handle,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
    );
  }
  
  Widget _buildComponentPreview(LayoutSlot slot) {
    final componentId = slot.componentId;
    if (componentId == null) {
      return Center(
        child: Icon(
          Icons.add,
          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
        ),
      );
    }
    
    final factory = ComponentRegistry.getFactory(componentId);
    if (factory == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              'Unknown',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      );
    }
    
    try {
      return ClipRRect(
        borderRadius: slot.borderRadius ?? BorderRadius.circular(8),
        child: factory(context, slot.componentConfig, _mockState),
      );
    } catch (e) {
      return Center(
        child: Icon(
          _getComponentIcon(componentId),
          size: 32,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }
  
  void _showComponentConfig(BuildContext context, LayoutSlot slot) {
    final componentId = slot.componentId;
    if (componentId == null) return;
    
    // Get component instance to build config panel
    final component = _getComponentInstance(componentId);
    if (component == null) return;
    
    final configPanel = component.buildConfigPanel(
      context,
      slot.componentConfig,
      (newConfig) {
        setState(() {
          final slotIndex = _slots.indexWhere(
            (s) => s.row == slot.row && s.column == slot.column,
          );
          if (slotIndex >= 0) {
            _slots[slotIndex] = slot.copyWith(componentConfig: newConfig);
          }
        });
      },
    );
    
    if (configPanel == null) {
      // No config panel for this component
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No configuration options available')),
      );
      return;
    }
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Configure ${_getComponentName(componentId)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Flexible(child: configPanel),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
  
  NowPlayingComponent? _getComponentInstance(String componentId) {
    // Import and instantiate components
    switch (componentId) {
      case 'progress_slider':
        return ProgressSliderComponent();
      case 'cover_art':
        return CoverArtComponent();
      case 'control_buttons':
        return ControlButtonsComponent();
      case 'track_info':
        return TrackInfoComponent();
      case 'visualizer':
        return VisualizerComponent();
      case 'lyrics':
        return LyricsComponent();
      default:
        return null;
    }
  }

  String _getComponentName(String componentId) {
    switch (componentId) {
      case 'cover_art':
        return 'Cover Art';
      case 'progress_slider':
        return 'Progress';
      case 'control_buttons':
        return 'Controls';
      case 'track_info':
        return 'Track Info';
      case 'visualizer':
        return 'Visualizer';
      case 'lyrics':
        return 'Lyrics';
      default:
        return componentId;
    }
  }
  
  IconData _getComponentIcon(String componentId) {
    switch (componentId) {
      case 'cover_art':
        return Icons.album;
      case 'progress_slider':
        return Icons.timeline;
      case 'control_buttons':
        return Icons.play_circle;
      case 'track_info':
        return Icons.info;
      case 'visualizer':
        return Icons.graphic_eq;
      case 'lyrics':
        return Icons.text_fields;
      default:
        return Icons.widgets;
    }
  }

  Widget _buildEmptySlot(int row, int column) {
    return DragTarget<String>(
      onAccept: (componentId) {
        _addComponent(componentId, row, column);
      },
      builder: (context, candidateData, rejectedData) {
        final isTargeted = candidateData.isNotEmpty;
        final isRejected = rejectedData.isNotEmpty;
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isRejected
                  ? Theme.of(context).colorScheme.error
                  : isTargeted
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).dividerColor.withOpacity(0.3),
              width: isTargeted || isRejected ? 3 : 1,
              style: BorderStyle.solid,
            ),
            color: isRejected
                ? Theme.of(context).colorScheme.errorContainer.withOpacity(0.2)
                : isTargeted
                    ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                    : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isRejected ? Icons.block : Icons.add_circle_outline,
                  color: isRejected
                      ? Theme.of(context).colorScheme.error
                      : isTargeted
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
                  size: 32,
                ),
                if (isTargeted) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Drop here',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
