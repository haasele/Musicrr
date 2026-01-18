import 'package:freezed_annotation/freezed_annotation.dart';

part 'album.freezed.dart';
part 'album.g.dart';

@freezed
class Album with _$Album {
  const factory Album({
    required String id,
    required String title,
    required String artist,
    String? artistId,
    String? coverArtUri,
    int? year,
    int? trackCount,
    String? providerId,
  }) = _Album;

  factory Album.fromJson(Map<String, dynamic> json) => _$AlbumFromJson(json);
}
