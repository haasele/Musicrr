import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/media_provider.dart';
import '../../core/providers/provider_repository.dart';
import '../../core/storage/playlist_repository.dart';
import '../../shared/widgets/cover_art_widget.dart';
import '../providers/provider_settings_screen.dart';
import 'artists_view.dart';
import 'albums_view.dart';
import 'songs_view.dart';

class ProviderDetailView extends ConsumerStatefulWidget {
  final MediaProvider provider;
  
  const ProviderDetailView({
    super.key,
    required this.provider,
  });
  
  @override
  ConsumerState<ProviderDetailView> createState() => _ProviderDetailViewState();
}

class _ProviderDetailViewState extends ConsumerState<ProviderDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.provider.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProviderSettingsScreen(
                    providerId: widget.provider.id,
                  ),
                ),
              );
            },
            tooltip: 'Provider Settings',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.playlist_play), text: 'Playlists'),
            Tab(icon: Icon(Icons.person), text: 'Artists'),
            Tab(icon: Icon(Icons.album), text: 'Albums'),
            Tab(icon: Icon(Icons.music_note), text: 'Songs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPlaylistsTab(),
          ArtistsView(providerId: widget.provider.id),
          AlbumsView(providerId: widget.provider.id),
          SongsView(providerId: widget.provider.id),
        ],
      ),
    );
  }
  
  Widget _buildPlaylistsTab() {
    final playlistRepo = ref.watch(playlistRepositoryProvider);
    final providerRepo = ref.watch(providerRepositoryProvider);
    
    return FutureBuilder(
      future: Future.wait([
        playlistRepo.getAllPlaylists(),
        providerRepo.getPlaylists(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final results = snapshot.data!;
        final userPlaylists = results[0] as List;
        final providerPlaylists = results[1] as List;
        final allPlaylists = [...userPlaylists, ...providerPlaylists];
        
        return Column(
          children: [
            if (allPlaylists.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.playlist_add,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No playlists',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create a playlist to organize your music',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: allPlaylists.length,
                  itemBuilder: (context, index) {
                    final playlist = allPlaylists[index];
                    return ListTile(
                      leading: CoverArtWidget(
                        coverArtUri: playlist.coverArtUri,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.circular(8),
                        placeholder: const Icon(Icons.playlist_play),
                      ),
                      title: Text(playlist.name),
                      subtitle: playlist.description != null
                          ? Text(playlist.description!)
                          : Text('${playlist.trackCount ?? 0} tracks'),
                      trailing: playlist.isAutoGenerated == false
                          ? IconButton(
                              icon: const Icon(Icons.more_vert),
                              onPressed: () {
                                // Show playlist options menu
                              },
                            )
                          : null,
                      onTap: () {
                        // TODO: Navigate to playlist detail
                      },
                    );
                  },
                ),
              ),
            // Create playlist button
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: () => _showCreatePlaylistDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Create Playlist'),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCreatePlaylistDialog(BuildContext context, WidgetRef ref) async {
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
        await playlistRepo.createPlaylist(
          name: nameController.text.trim(),
          description: descriptionController.text.trim().isEmpty 
              ? null 
              : descriptionController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Playlist created')),
          );
          setState(() {}); // Refresh the list
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
}
