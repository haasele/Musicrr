import 'package:freezed_annotation/freezed_annotation.dart';

part 'lyrics.freezed.dart';
part 'lyrics.g.dart';

/// Lyrics model with LRC timestamp support
@freezed
class Lyrics with _$Lyrics {
  const factory Lyrics({
    required String id,
    required String songId,
    required String lyricsText,
    List<LrcLine>? lrcLines, // Timestamped lyrics lines
    @Default(false) bool isSynced,
    String? source, // 'local', 'embedded', 'online'
    required DateTime createdAt,
  }) = _Lyrics;
  
  factory Lyrics.fromJson(Map<String, dynamic> json) => _$LyricsFromJson(json);
}

/// LRC timestamped line
@freezed
class LrcLine with _$LrcLine {
  const factory LrcLine({
    required int timestampMs, // Timestamp in milliseconds
    required String text,
  }) = _LrcLine;
  
  factory LrcLine.fromJson(Map<String, dynamic> json) => _$LrcLineFromJson(json);
}
