import 'package:flutter/material.dart';
import '../layout/layout_engine.dart';

class ComponentLibraryPanel extends StatelessWidget {
  final Function(String) onComponentSelected;

  const ComponentLibraryPanel({
    super.key,
    required this.onComponentSelected,
  });

  @override
  Widget build(BuildContext context) {
    final components = ComponentRegistry.registeredComponentIds;

    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Component Library',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 8),
              // Component list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: components.length,
                  itemBuilder: (context, index) {
                    final componentId = components[index];
                    return _ComponentLibraryItem(
                      componentId: componentId,
                      onTap: () => onComponentSelected(componentId),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ComponentLibraryItem extends StatelessWidget {
  final String componentId;
  final VoidCallback onTap;

  const _ComponentLibraryItem({
    required this.componentId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Draggable<String>(
      data: componentId,
      feedback: Material(
        elevation: 8,
        child: Container(
          width: 120,
          height: 60,
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Center(
            child: Text(
              _getComponentName(componentId),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ),
      child: Card(
        child: ListTile(
          leading: Icon(_getComponentIcon(componentId)),
          title: Text(_getComponentName(componentId)),
          subtitle: Text(_getComponentDescription(componentId)),
          trailing: const Icon(Icons.drag_handle),
          onTap: onTap,
        ),
      ),
    );
  }

  String _getComponentName(String componentId) {
    switch (componentId) {
      case 'cover_art':
        return 'Cover Art';
      case 'progress_slider':
        return 'Progress Slider';
      case 'control_buttons':
        return 'Control Buttons';
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

  String _getComponentDescription(String componentId) {
    switch (componentId) {
      case 'cover_art':
        return 'Album artwork display';
      case 'progress_slider':
        return 'Playback progress bar';
      case 'control_buttons':
        return 'Play, pause, skip controls';
      case 'track_info':
        return 'Song title and artist';
      case 'visualizer':
        return 'Audio visualizer';
      case 'lyrics':
        return 'Lyrics display';
      default:
        return '';
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
}
