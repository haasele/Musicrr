import 'package:flutter/material.dart';
import 'now_playing_component.dart';
import '../layout/layout_engine.dart';

class TrackInfoComponent extends NowPlayingComponent {
  TrackInfoComponent()
      : super(
          id: 'track_info',
          type: 'track_info',
          defaultConfig: const {
            'layout': 'stacked', // 'stacked', 'inline', 'compact'
            'showTitle': true,
            'showArtist': true,
            'showAlbum': true,
            'textAlign': 'center', // 'left', 'center', 'right'
          },
        );
  
  @override
  List<SizeOption> getSupportedSizes() {
    return const [
      SizeOption(rowSpan: 1, columnSpan: 2, label: 'Half Width'),
      SizeOption(rowSpan: 1, columnSpan: 4, label: 'Full Width'),
      SizeOption(rowSpan: 2, columnSpan: 2, label: 'Square'),
    ];
  }
  
  @override
  bool canResizeTo(int rowSpan, int columnSpan) {
    if (rowSpan == 1 && (columnSpan == 2 || columnSpan == 4)) return true;
    if (rowSpan == 2 && columnSpan == 2) return true;
    return false;
  }
  
  @override
  Widget build(BuildContext context, Map<String, dynamic> config, NowPlayingState state) {
    final layout = config['layout'] as String? ?? 'stacked';
    final showTitle = config['showTitle'] as bool? ?? true;
    final showArtist = config['showArtist'] as bool? ?? true;
    final showAlbum = config['showAlbum'] as bool? ?? true;
    final textAlign = _parseTextAlign(config['textAlign'] as String? ?? 'center');
    
    final song = state.currentSong;
    if (song == null) {
      return Center(
        child: Text(
          'No track',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    
    switch (layout) {
      case 'inline':
        return _buildInlineLayout(context, song, showTitle, showArtist, showAlbum, textAlign);
      case 'compact':
        return _buildCompactLayout(context, song, showTitle, showArtist, showAlbum, textAlign);
      default:
        return _buildStackedLayout(context, song, showTitle, showArtist, showAlbum, textAlign);
    }
  }
  
  Widget _buildStackedLayout(
    BuildContext context,
    dynamic song,
    bool showTitle,
    bool showArtist,
    bool showAlbum,
    TextAlign textAlign,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: _getCrossAxisAlignment(textAlign),
      children: [
        if (showTitle)
          Text(
            song.title,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: textAlign,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        if (showTitle && showArtist) const SizedBox(height: 4),
        if (showArtist)
          Text(
            song.artist,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: textAlign,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        if (showArtist && showAlbum) const SizedBox(height: 2),
        if (showAlbum)
          Text(
            song.album,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: textAlign,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
  
  Widget _buildInlineLayout(
    BuildContext context,
    dynamic song,
    bool showTitle,
    bool showArtist,
    bool showAlbum,
    TextAlign textAlign,
  ) {
    final parts = <String>[];
    if (showTitle) parts.add(song.title);
    if (showArtist) parts.add(song.artist);
    if (showAlbum) parts.add(song.album);
    
    return Center(
      child: Text(
        parts.join(' • '),
        style: Theme.of(context).textTheme.bodyLarge,
        textAlign: textAlign,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
  
  Widget _buildCompactLayout(
    BuildContext context,
    dynamic song,
    bool showTitle,
    bool showArtist,
    bool showAlbum,
    TextAlign textAlign,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: _getCrossAxisAlignment(textAlign),
      children: [
        if (showTitle)
          Text(
            song.title,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: textAlign,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        if (showArtist)
          Text(
            song.artist,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: textAlign,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
  
  TextAlign _parseTextAlign(String align) {
    switch (align) {
      case 'left':
        return TextAlign.left;
      case 'right':
        return TextAlign.right;
      default:
        return TextAlign.center;
    }
  }
  
  CrossAxisAlignment _getCrossAxisAlignment(TextAlign align) {
    switch (align) {
      case TextAlign.left:
        return CrossAxisAlignment.start;
      case TextAlign.right:
        return CrossAxisAlignment.end;
      default:
        return CrossAxisAlignment.center;
    }
  }
}
