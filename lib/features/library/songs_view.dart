import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/provider_repository.dart';
import '../../core/models/song.dart';
import '../../core/audio/audio_engine.dart';
import '../../core/storage/playlist_repository.dart';
import '../../shared/widgets/cover_art_widget.dart';

final songsProvider = FutureProvider.family<List<Song>, SongsFilter>((ref, filter) async {
  final repository = ref.watch(providerRepositoryProvider);
  final allSongs = await repository.getSongs(
    albumId: filter.albumId,
    artistId: filter.artistId,
  );
  // Filter by provider if specified
  if (filter.providerId != null) {
    return allSongs.where((s) => s.providerId == filter.providerId).toList();
  }
  return allSongs;
});

class SongsFilter {
  final String? albumId;
  final String? artistId;
  final String? providerId;

  const SongsFilter({this.albumId, this.artistId, this.providerId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SongsFilter &&
          runtimeType == other.runtimeType &&
          albumId == other.albumId &&
          artistId == other.artistId &&
          providerId == other.providerId;

  @override
  int get hashCode => albumId.hashCode ^ artistId.hashCode ^ providerId.hashCode;
}

class SongsView extends ConsumerStatefulWidget {
  final String? albumId;
  final String? artistId;
  final String? providerId;
  
  const SongsView({super.key, this.albumId, this.artistId, this.providerId});

  @override
  ConsumerState<SongsView> createState() => _SongsViewState();
}

class _SongsViewState extends ConsumerState<SongsView> {
  final Set<String> _selectedSongs = {};
  bool _isSelectionMode = false;

  @override
  Widget build(BuildContext context) {
    final filter = SongsFilter(albumId: widget.albumId, artistId: widget.artistId, providerId: widget.providerId);
    final songsAsync = ref.watch(songsProvider(filter));

    return songsAsync.when(
      data: (songs) {
        if (songs.isEmpty) {
          return const Center(
            child: Text('No songs found'),
          );
        }

        return Column(
          children: [
            if (_isSelectionMode)
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Row(
                  children: [
                    Text(
                      '${_selectedSongs.length} selected',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const Spacer(),
                    if (_selectedSongs.isNotEmpty) ...[
                      TextButton.icon(
                        onPressed: () => _createPlaylistFromSelection(context, ref, songs),
                        icon: const Icon(Icons.playlist_add),
                        label: const Text('Create Playlist'),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _addToPlaylist(context, ref),
                        icon: const Icon(Icons.add),
                        label: const Text('Add to Playlist'),
                      ),
                    ],
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _isSelectionMode = false;
                          _selectedSongs.clear();
                        });
                      },
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  final song = songs[index];
                  final isSelected = _selectedSongs.contains(song.id);
                  return ListTile(
                    leading: _buildCoverArt(song),
                    title: Text(song.title),
                    subtitle: Text(song.artist),
                    trailing: _isSelectionMode
                        ? Checkbox(
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedSongs.add(song.id);
                                } else {
                                  _selectedSongs.remove(song.id);
                                }
                              });
                            },
                          )
                        : Text(_formatDuration(song.duration)),
                    onTap: () {
                      if (_isSelectionMode) {
                        setState(() {
                          if (isSelected) {
                            _selectedSongs.remove(song.id);
                          } else {
                            _selectedSongs.add(song.id);
                          }
                        });
                      } else {
                        final engine = ref.read(audioEngineProvider);
                        engine.play(song);
                      }
                    },
                    onLongPress: () {
                      if (!_isSelectionMode) {
                        setState(() {
                          _isSelectionMode = true;
                          _selectedSongs.add(song.id);
                        });
                      }
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
    );
  }

  Widget _buildCoverArt(Song song) {
    return CoverArtWidget(
      coverArtUri: song.coverArtUri,
      width: 56,
      height: 56,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(8),
    );
  }

  Future<void> _createPlaylistFromSelection(BuildContext context, WidgetRef ref, List<Song> songs) async {
    final selectedSongs = songs.where((s) => _selectedSongs.contains(s.id)).toList();
    if (selectedSongs.isEmpty) return;

    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Playlist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Playlist Name',
                hintText: 'My Playlist',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            Text(
              '${selectedSongs.length} songs will be added',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      try {
        final playlistRepo = ref.read(playlistRepositoryProvider);
        final songIds = selectedSongs.map((s) => s.id).toList();
        
        await playlistRepo.createPlaylist(
          name: nameController.text.trim(),
          description: descriptionController.text.trim().isEmpty 
              ? null 
              : descriptionController.text.trim(),
          songIds: songIds,
          coverArtUri: selectedSongs.first.coverArtUri,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Playlist created')),
          );
          setState(() {
            _isSelectionMode = false;
            _selectedSongs.clear();
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating playlist: $e')),
          );
        }
      }
    }
  }

  Future<void> _addToPlaylist(BuildContext context, WidgetRef ref) async {
    if (_selectedSongs.isEmpty) return;

    try {
      final playlistRepo = ref.read(playlistRepositoryProvider);
      final playlists = await playlistRepo.getAllPlaylists();

      if (playlists.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No playlists found. Create one first.')),
        );
        return;
      }

      final selectedPlaylist = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Add to Playlist'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                final playlist = playlists[index];
                return ListTile(
                  leading: playlist.coverArtUri != null
                      ? Image.network(playlist.coverArtUri!)
                      : const Icon(Icons.playlist_play),
                  title: Text(playlist.name),
                  subtitle: Text('${playlist.trackCount ?? 0} tracks'),
                  onTap: () => Navigator.pop(context, playlist.id),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (selectedPlaylist != null) {
        await playlistRepo.addSongsToPlaylist(selectedPlaylist, _selectedSongs.toList());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Songs added to playlist')),
          );
          setState(() {
            _isSelectionMode = false;
            _selectedSongs.clear();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
