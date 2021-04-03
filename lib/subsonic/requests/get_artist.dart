import 'dart:convert';

import 'package:subsound/subsonic/requests/get_starred2.dart';
import 'package:subsound/utils/duration.dart';

import '../base_request.dart';
import '../subsonic.dart';
import 'get_cover_art.dart';

class AlbumResultSimple {
  final String id;
  final String? parent;
  final String title;
  final String name;
  final String artistName;
  final String artistId;
  final String? coverArtId;
  final String? coverArtLink;
  final int year;
  final Duration duration;
  final int songCount;
  final int playCount;
  final bool isVideo;
  final DateTime createdAt;
  final DateTime? starredAt;

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
    this.createdAt,
    this.starredAt,
  );

  AlbumResultSimple.named({
    required this.id,
    this.parent,
    required this.title,
    required this.name,
    required this.artistName,
    required this.artistId,
    required this.coverArtId,
    required this.coverArtLink,
    required this.year,
    required this.duration,
    required this.songCount,
    this.playCount = 0,
    this.isVideo = false,
    required this.createdAt,
    required this.starredAt,
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

    // navidrome needs this call to load extra artistinfo for next call
    ctx.client.get(ctx.buildRequestUri('getArtistInfo2', params: {'id': id}));

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (data['subsonic-response']['status'] != 'ok') {
      throw StateError(data);
    }

    final artistData = data['subsonic-response']['artist'];

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
        parseDateTime(album['starred']),
      );
    }).toList()
      ..sort((a, b) => b.year.compareTo(a.year));

    final firstAlbumWithCover =
        albums.firstWhere((element) => element.coverArtLink != null);

    final firstAlbumCoverLink = firstAlbumWithCover != null
        ? firstAlbumWithCover.coverArtLink
        : FallbackImageUrl;

    final coverArtLink = artistData['artistImageUrl'] ?? firstAlbumCoverLink;

    // log('firstAlbumCoverLink=$firstAlbumCoverLink');
    // log('coverArtLink=$coverArtLink');

    final artistResult = ArtistResult(
      artistData['id'],
      artistData['name'],
      coverArtLink,
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
