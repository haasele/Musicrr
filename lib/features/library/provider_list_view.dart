import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/provider_repository.dart';
import '../../core/providers/media_provider.dart';
import 'provider_detail_view.dart';

class ProviderListView extends ConsumerStatefulWidget {
  const ProviderListView({super.key});
  
  @override
  ConsumerState<ProviderListView> createState() => _ProviderListViewState();
}

class _ProviderListViewState extends ConsumerState<ProviderListView> {
  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(providerRepositoryProvider);
    final providers = repository.providers;
    
    if (providers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No providers configured',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Add a provider to start browsing your music',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: providers.length,
      itemBuilder: (context, index) {
        final provider = providers[index];
        return _ProviderListTile(provider: provider);
      },
    );
  }
  
}

class _ProviderListTile extends ConsumerWidget {
  final MediaProvider provider;
  
  const _ProviderListTile({required this.provider});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Icon(
        _getProviderIcon(provider),
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(provider.name),
      subtitle: Text(provider.id),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            provider.isEnabled ? Icons.check_circle : Icons.cancel,
            color: provider.isEnabled
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProviderDetailView(provider: provider),
          ),
        );
      },
    );
  }
  
  IconData _getProviderIcon(MediaProvider provider) {
    // Determine icon based on provider type
    if (provider.id.contains('local')) {
      return Icons.folder;
    } else if (provider.id.contains('webdav')) {
      return Icons.cloud;
    } else if (provider.id.contains('smb')) {
      return Icons.storage;
    } else if (provider.id.contains('subsonic')) {
      return Icons.music_note;
    } else if (provider.id.contains('jellyfin')) {
      return Icons.library_music;
    }
    return Icons.music_note;
  }
}
