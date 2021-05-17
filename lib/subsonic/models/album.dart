import 'package:subsound/subsonic/context.dart';
import 'package:subsound/subsonic/requests/get_cover_art.dart';

class Album {
  final String id;
  final String? parent;
  final String title;
  final String artist;
  final bool isDir;
  final String coverArtId;
  final String coverArtLink;

  Album({
    required this.id,
    this.parent,
    required this.title,
    required this.artist,
    this.isDir = false,
    required this.coverArtId,
    required this.coverArtLink,
  });

  factory Album.parse(SubsonicContext ctx, Map<String, dynamic> data) {
    final coverArtId = data['coverArt'] as String?;
    final coverArtLink =
        coverArtId != null ? GetCoverArt(coverArtId).getImageUrl(ctx) : '';

    return Album(
      id: data['id'].toString(),
      parent: data['parent'] as String? ?? '',
      title: data['title'] as String? ?? '',
      artist: data['artist'] as String? ?? '',
      isDir: data['isDir'] as bool? ?? false,
      coverArtId: coverArtId ?? '',
      coverArtLink: coverArtLink,
    );
  }
}
