import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/provider_repository.dart';
import '../../core/models/album.dart';
import '../../shared/widgets/cover_art_widget.dart';

final albumsProvider = FutureProvider.family<List<Album>, AlbumsFilter>((ref, filter) async {
  final repository = ref.watch(providerRepositoryProvider);
  final allAlbums = await repository.getAlbums(artistId: filter.artistId);
  // Filter by provider if specified
  if (filter.providerId != null) {
    return allAlbums.where((a) => a.providerId == filter.providerId).toList();
  }
  return allAlbums;
});

class AlbumsFilter {
  final String? artistId;
  final String? providerId;
  
  const AlbumsFilter({this.artistId, this.providerId});
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlbumsFilter &&
          runtimeType == other.runtimeType &&
          artistId == other.artistId &&
          providerId == other.providerId;
  
  @override
  int get hashCode => artistId.hashCode ^ providerId.hashCode;
}

class AlbumsView extends ConsumerWidget {
  final String? artistId;
  final String? providerId;
  
  const AlbumsView({super.key, this.artistId, this.providerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = AlbumsFilter(artistId: artistId, providerId: providerId);
    final albumsAsync = ref.watch(albumsProvider(filter));

    return albumsAsync.when(
      data: (albums) {
        if (albums.isEmpty) {
          return const Center(
            child: Text('No albums found'),
          );
        }

        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          padding: const EdgeInsets.all(12),
          itemCount: albums.length,
          itemBuilder: (context, index) {
            final album = albums[index];
            return Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  // TODO: Navigate to album detail
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CoverArtWidget(
                        coverArtUri: album.coverArtUri,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            album.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            album.artist,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (album.trackCount != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${album.trackCount} tracks',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
