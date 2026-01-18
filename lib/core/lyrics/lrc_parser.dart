import 'dart:convert';
import '../models/lyrics.dart';

/// Parser for LRC (Lyrics) format files
class LrcParser {
  /// Parse LRC content into Lyrics model
  static Lyrics? parseLrc(String lrcContent, String songId, {String? source}) {
    if (lrcContent.trim().isEmpty) {
      return null;
    }
    
    final lines = lrcContent.split('\n');
    final lrcLines = <LrcLine>[];
    final plainTextLines = <String>[];
    bool hasTimestamps = false;
    
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      
      // Parse timestamped lines: [mm:ss.xx] or [mm:ss.xxx] or [mm:ss]
      final timestampRegex = RegExp(r'\[(\d{2}):(\d{2})(?:\.(\d{2,3}))?\]');
      final matches = timestampRegex.allMatches(trimmed);
      
      if (matches.isNotEmpty) {
        hasTimestamps = true;
        // Get text after last timestamp
        final lastMatch = matches.last;
        final text = trimmed.substring(lastMatch.end).trim();
        
        if (text.isNotEmpty) {
          // Use first timestamp for now (LRC can have multiple timestamps per line)
          final match = matches.first;
          final minutes = int.parse(match.group(1)!);
          final seconds = int.parse(match.group(2)!);
          final milliseconds = match.group(3) != null
              ? int.parse(match.group(3)!.padRight(3, '0').substring(0, 3))
              : 0;
          
          final timestampMs = (minutes * 60 + seconds) * 1000 + milliseconds;
          
          lrcLines.add(LrcLine(
            timestampMs: timestampMs,
            text: text,
          ));
          plainTextLines.add(text);
        }
      } else if (!trimmed.startsWith('[') || !trimmed.contains(':')) {
        // Plain text line (no timestamp)
        plainTextLines.add(trimmed);
      }
    }
    
    // Sort by timestamp if synced
    if (hasTimestamps && lrcLines.isNotEmpty) {
      lrcLines.sort((a, b) => a.timestampMs.compareTo(b.timestampMs));
    }
    
    final lyricsText = plainTextLines.join('\n');
    
    if (lyricsText.isEmpty && lrcLines.isEmpty) {
      return null;
    }
    
    return Lyrics(
      id: 'lyrics_${songId}_${DateTime.now().millisecondsSinceEpoch}',
      songId: songId,
      lyricsText: lyricsText,
      lrcLines: hasTimestamps && lrcLines.isNotEmpty ? lrcLines : null,
      isSynced: hasTimestamps && lrcLines.isNotEmpty,
      source: source,
      createdAt: DateTime.now(),
    );
  }
  
  /// Parse LRC file content from bytes
  static Lyrics? parseLrcFromBytes(List<int> bytes, String songId, {String? source}) {
    try {
      final content = utf8.decode(bytes);
      return parseLrc(content, songId, source: source);
    } catch (e) {
      return null;
    }
  }
  
  /// Get lyrics line at specific timestamp
  static String? getLineAtTimestamp(List<LrcLine> lines, int timestampMs) {
    if (lines.isEmpty) return null;
    
    // Binary search for the line at or before the timestamp
    int left = 0;
    int right = lines.length - 1;
    LrcLine? currentLine;
    
    while (left <= right) {
      final mid = (left + right) ~/ 2;
      final line = lines[mid];
      
      if (line.timestampMs <= timestampMs) {
        currentLine = line;
        left = mid + 1;
      } else {
        right = mid - 1;
      }
    }
    
    return currentLine?.text;
  }
  
  /// Get all lines up to a timestamp
  static List<String> getLinesUpToTimestamp(List<LrcLine> lines, int timestampMs) {
    return lines
        .where((line) => line.timestampMs <= timestampMs)
        .map((line) => line.text)
        .toList();
  }
}
