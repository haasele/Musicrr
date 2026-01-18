import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/provider_repository.dart';
import '../../core/models/artist.dart';

final artistsProvider = FutureProvider.family<List<Artist>, String?>((ref, providerId) async {
  final repository = ref.watch(providerRepositoryProvider);
  final allArtists = await repository.getArtists();
  // Filter by provider if specified
  if (providerId != null) {
    return allArtists.where((a) => a.providerId == providerId).toList();
  }
  return allArtists;
});

class ArtistsView extends ConsumerWidget {
  final String? providerId;
  
  const ArtistsView({super.key, this.providerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistsAsync = ref.watch(artistsProvider(providerId));

    return artistsAsync.when(
      data: (artists) {
        if (artists.isEmpty) {
          return const Center(
            child: Text('No artists found'),
          );
        }

        return ListView.builder(
          itemCount: artists.length,
          itemBuilder: (context, index) {
            final artist = artists[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                child: Icon(
                  Icons.person,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              title: Text(artist.name),
              subtitle: Text('${artist.albumCount ?? 0} albums • ${artist.trackCount ?? 0} tracks'),
              onTap: () {
                // TODO: Navigate to artist detail
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
    );
  }
}
