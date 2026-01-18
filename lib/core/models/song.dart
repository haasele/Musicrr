import 'package:freezed_annotation/freezed_annotation.dart';

part 'song.freezed.dart';
part 'song.g.dart';

@freezed
class Song with _$Song {
  const factory Song({
    required String id,
    required String title,
    required String artist,
    required String album,
    String? albumId,
    required int duration, // milliseconds
    required String uri,
    String? coverArtUri,
    int? trackNumber,
    int? discNumber,
    String? genre,
    int? year,
    String? providerId,
  }) = _Song;

  factory Song.fromJson(Map<String, dynamic> json) => _$SongFromJson(json);
}
