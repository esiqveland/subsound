import 'dart:convert';
import 'dart:developer';

import 'package:subsound/utils/duration.dart';

import '../base_request.dart';
import '../subsonic.dart';
import 'get_cover_art.dart';

class AlbumResultSimple {
  final String id;
  final String parent;
  final String title;
  final String name;
  final String artistName;
  final String artistId;
  final String coverArtId;
  final String coverArtLink;
  final int year;
  final Duration duration;
  final int songCount;
  final int playCount;
  final bool isVideo;
  final DateTime createdAt;

  AlbumResultSimple(
      this.id,
      this.parent,
      this.title,
      this.name,
      this.artistName,
      this.artistId,
      this.coverArtId,
      this.coverArtLink,
      this.year,
      this.duration,
      this.songCount,
      this.playCount,
      this.isVideo,
      this.createdAt);

  AlbumResultSimple.named({
    this.id,
    this.parent,
    this.title,
    this.name,
    this.artistName,
    this.artistId,
    this.coverArtId,
    this.coverArtLink,
    this.year,
    this.duration,
    this.songCount,
    this.playCount,
    this.isVideo,
    this.createdAt,
  });

  String durationNice() {
    return formatDuration(duration);
  }
}

class ArtistResult {
  final String id;
  final String name;
  final String coverArtId;
  final String coverArtLink;
  final int albumCount;
  final List<AlbumResultSimple> albums;

  ArtistResult(this.id, this.name, this.coverArtId, this.coverArtLink,
      this.albumCount, this.albums);
}

class GetArtist extends BaseRequest<ArtistResult> {
  final String id;

  GetArtist(this.id);

  @override
  String get sinceVersion => '1.8.0';

  @override
  Future<SubsonicResponse<ArtistResult>> run(SubsonicContext ctx) async {
    final response = await ctx.client
        .get(ctx.buildRequestUri('getArtist', params: {'id': id}));

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (data['subsonic-response']['status'] != 'ok') {
      throw StateError(data);
    }

    final artistData = data['subsonic-response']['artist'];
    final coverArtId = artistData['coverArt'];

    final albums = (artistData['album'] as List).map((album) {
      final coverArtId = album['coverArt'];
      final coverArtLink = coverArtId != null
          ? GetCoverArt(coverArtId).getImageUrl(ctx)
          : artistData['artistImageUrl'] ?? FallbackImageUrl;

      final duration = getDuration(album['duration']);

      return AlbumResultSimple(
        album['id'],
        album['parent'],
        album['title'],
        album['name'],
        album['artist'],
        album['artistId'],
        coverArtId,
        coverArtLink,
        album['year'] ?? 0,
        duration,
        album['songCount'] ?? 0,
        album['playCount'] ?? 0,
        album['isVideo'] ?? false,
        DateTime.parse(album['created']),
      );
    }).toList()
      ..sort((a, b) => b.year.compareTo(a.year));

    final firstAlbumWithCover =
        albums.firstWhere((element) => element.coverArtLink != null);

    final firstAlbumCoverLink = firstAlbumWithCover != null
        ? firstAlbumWithCover.coverArtLink
        : FallbackImageUrl;

    final coverArtLink = coverArtId != null
        ? GetCoverArt(coverArtId).getImageUrl(ctx)
        : firstAlbumCoverLink ?? artistData['artistImageUrl'];

    log('firstAlbumCoverLink=$firstAlbumCoverLink');
    log('coverArtLink=$coverArtLink');

    final artistResult = ArtistResult(
      artistData['id'],
      artistData['name'],
      coverArtId,
      coverArtLink,
      artistData['albumCount'],
      albums,
    );

    return SubsonicResponse(
      ResponseStatus.ok,
      data['subsonic-response']['version'],
      artistResult,
    );
  }
}
