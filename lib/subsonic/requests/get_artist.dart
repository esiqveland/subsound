import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:pedantic/pedantic.dart';
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

  static AlbumResultSimple fromJson(
    Map<String, dynamic> albumData,
    SubsonicContext ctx,
  ) {
    final songArtId = albumData['coverArt'] as String? ?? '';
    final coverArtLink = songArtId.isNotEmpty
        ? GetCoverArt(songArtId).getImageUrl(ctx)
        : FallbackImageUrl;

    final duration = getDuration(albumData['duration']);

    final id = albumData['id'] as String;

    return AlbumResultSimple.named(
      id: id,
      title: albumData['title'] as String? ?? '',
      name: albumData['name'] as String? ?? '',
      artistName: albumData['artist'] as String? ?? '',
      artistId: albumData['artistId'] as String? ?? '',
      coverArtId: songArtId.isEmpty ? coverArtLink : songArtId,
      coverArtLink: coverArtLink,
      year: albumData['year'] as int? ?? 0,
      duration: duration,
      songCount: albumData['songCount'] as int? ?? 0,
      createdAt: DateTime.parse(albumData['created'] as String),
      starredAt: parseDateTime(albumData['starred'] as String?),
    );
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
    unawaited(ctx.client.get(ctx.buildRequestUri(
      'getArtistInfo2',
      params: {'id': id},
    )));

    final data =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    if (data['subsonic-response']['status'] != 'ok') {
      throw Exception(data);
    }

    final artistData = data['subsonic-response']['artist'];

    final albums = (artistData['album'] as List).map((album) {
      final coverArtId = album['coverArt'] as String?;
      final coverArtLink = coverArtId != null
          ? GetCoverArt(coverArtId).getImageUrl(ctx)
          : artistData['artistImageUrl'] as String? ?? FallbackImageUrl;

      final duration = getDuration(album['duration']);

      return AlbumResultSimple(
        album['id'].toString() as String,
        album['parent'] as String,
        album['title'] as String,
        album['name'] as String,
        album['artist'] as String,
        album['artistId'] as String,
        coverArtId,
        coverArtLink,
        album['year'] as int? ?? 0,
        duration,
        album['songCount'] as int? ?? 0,
        album['playCount'] as int? ?? 0,
        album['isVideo'] as bool? ?? false,
        DateTime.parse(album['created'] as String),
        parseDateTime(album['starred'] as String?),
      );
    }).toList()
      ..sort((a, b) => b.year.compareTo(a.year));

    final firstAlbumWithCover = albums.firstWhereOrNull(
      (a) => a.coverArtLink != null,
    );

    final firstAlbumCoverLink = firstAlbumWithCover != null
        ? firstAlbumWithCover.coverArtLink
        : FallbackImageUrl;

    final name = artistData['name'] as String;
    final coverArtLink =
        artistData['artistImageUrl'] as String? ?? firstAlbumCoverLink ?? '';

    // log('firstAlbumCoverLink=$firstAlbumCoverLink');
    //log('id=$id $name coverArtLink=$coverArtLink');

    final artistResult = ArtistResult(
      artistData['id'] as String,
      name,
      coverArtLink,
      coverArtLink,
      artistData['albumCount'] as int? ?? 0,
      albums,
    );

    return SubsonicResponse(
      ResponseStatus.ok,
      data['subsonic-response']['version'] as String,
      artistResult,
    );
  }
}
