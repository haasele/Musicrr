import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/song.dart';
import '../../core/models/lyrics.dart';
import '../../core/lyrics/lyrics_service.dart';

class LyricsSearchScreen extends ConsumerStatefulWidget {
  final Song song;
  
  const LyricsSearchScreen({
    super.key,
    required this.song,
  });
  
  @override
  ConsumerState<LyricsSearchScreen> createState() => _LyricsSearchScreenState();
}

class _LyricsSearchScreenState extends ConsumerState<LyricsSearchScreen> {
  bool _isSearching = false;
  Lyrics? _foundLyrics;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadExistingLyrics();
  }
  
  Future<void> _loadExistingLyrics() async {
    final service = ref.read(lyricsServiceProvider);
    final lyrics = await service.getLyrics(widget.song);
    if (mounted) {
      setState(() {
        _foundLyrics = lyrics;
      });
    }
  }
  
  Future<void> _searchLyrics() async {
    setState(() {
      _isSearching = true;
      _error = null;
      _foundLyrics = null;
    });
    
    try {
      final service = ref.read(lyricsServiceProvider);
      final lyrics = await service.searchLyrics(
        widget.song,
        allowOnline: false, // TODO: Add user preference for online search
      );
      
      if (mounted) {
        setState(() {
          _isSearching = false;
          _foundLyrics = lyrics;
          if (lyrics == null) {
            _error = 'No lyrics found';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _error = 'Error searching lyrics: $e';
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Lyrics'),
      ),
      body: Column(
        children: [
          // Song info
          ListTile(
            leading: const Icon(Icons.music_note),
            title: Text(widget.song.title),
            subtitle: Text('${widget.song.artist} • ${widget.song.album}'),
          ),
          const Divider(),
          
          // Search button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _isSearching ? null : _searchLyrics,
              icon: _isSearching
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              label: Text(_isSearching ? 'Searching...' : 'Search for Lyrics'),
            ),
          ),
          
          // Results
          Expanded(
            child: _buildResults(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }
    
    if (_foundLyrics == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lyrics,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No lyrics found',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching for lyrics',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Lyrics Found',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Source: ${_foundLyrics!.source ?? "Unknown"}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (_foundLyrics!.isSynced)
                  Chip(
                    label: const Text('Synced'),
                    avatar: const Icon(Icons.schedule, size: 16),
                  ),
                const SizedBox(height: 16),
                Text(
                  _foundLyrics!.lyricsText,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
