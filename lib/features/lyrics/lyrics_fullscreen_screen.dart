import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/lyrics.dart';
import '../../core/lyrics/lyrics_service.dart';
import '../../core/audio/audio_engine.dart';

class LyricsFullscreenScreen extends ConsumerStatefulWidget {
  final Lyrics lyrics;
  
  const LyricsFullscreenScreen({
    super.key,
    required this.lyrics,
  });
  
  @override
  ConsumerState<LyricsFullscreenScreen> createState() => _LyricsFullscreenScreenState();
}

class _LyricsFullscreenScreenState extends ConsumerState<LyricsFullscreenScreen> {
  final ScrollController _scrollController = ScrollController();
  int _currentLineIndex = 0;
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final playbackStateAsync = ref.watch(playbackStateProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lyrics'),
      ),
      body: playbackStateAsync.when(
        data: (state) {
          if (widget.lyrics.isSynced && widget.lyrics.lrcLines != null) {
            return _buildSyncedLyrics(state.positionMs);
          } else {
            return _buildUnsyncedLyrics();
          }
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
  
  Widget _buildSyncedLyrics(int positionMs) {
    final lines = widget.lyrics.lrcLines!;
    
    // Find current line index
    int currentIndex = 0;
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].timestampMs <= positionMs) {
        currentIndex = i;
      } else {
        break;
      }
    }
    
    // Auto-scroll to current line
    if (currentIndex != _currentLineIndex) {
      _currentLineIndex = currentIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients && currentIndex < lines.length) {
          final itemHeight = 60.0; // Approximate line height
          final targetOffset = (currentIndex * itemHeight) - 200; // Center offset
          _scrollController.animateTo(
            targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: lines.length,
      itemBuilder: (context, index) {
        final line = lines[index];
        final isCurrent = index == currentIndex;
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            line.text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: isCurrent ? 24 : 18,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isCurrent
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }
  
  Widget _buildUnsyncedLyrics() {
    final textLines = widget.lyrics.lyricsText.split('\n');
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: textLines.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            textLines[index],
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }
}
