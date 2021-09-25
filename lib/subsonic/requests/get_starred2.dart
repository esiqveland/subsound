import 'dart:convert';

import 'package:subsound/subsonic/requests/get_album.dart';
import 'package:subsound/subsonic/requests/get_artist.dart';
import 'package:subsound/subsonic/requests/get_cover_art.dart';
import 'package:subsound/utils/duration.dart';

import '../base_request.dart';
import '../subsonic.dart';

class GetStarred2Result {
  final List<AlbumResultSimple> albums;
  final List<SongResult> songs;
  final DateTime lastModified;

  GetStarred2Result({
    required this.albums,
    required this.songs,
    required this.lastModified,
  });
}

bool parseStarred(dynamic value) {
  if (value != null) {
    return true;
  } else {
    return false;
  }
}

DateTime? parseDateTime(String? value) {
  if (value != null) {
    return DateTime.tryParse(value);
  } else {
    return null;
  }
}

enum StarredSorting {
  recent,
}

class GetStarred2 extends BaseRequest<GetStarred2Result> {
  GetStarred2();

  @override
  String get sinceVersion => '1.8.0';

  @override
  Future<SubsonicResponse<GetStarred2Result>> run(SubsonicContext ctx) async {
    final response = await ctx.client.get(ctx.buildRequestUri('getStarred2'));

    final data =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    if (data['subsonic-response']['status'] != 'ok') {
      throw Exception(data);
    }

    final starred2Field =
        data['subsonic-response']['starred2'] as Map<String, dynamic>;
    final albumField = (starred2Field["album"] ?? []) as List<dynamic>;
    final songField = (starred2Field["song"] ?? []) as List<dynamic>;

    final lastModifiedField =
        data['subsonic-response']['starred2']['lastModified'] as int? ?? 0;
    final lastModified = DateTime.fromMillisecondsSinceEpoch(lastModifiedField);

    final albums = albumField.map((albumDataNew) {
      final coverArtId = albumDataNew['coverArt'] as String? ?? '';

      final coverArtLink = coverArtId.isNotEmpty
          ? GetCoverArt(coverArtId).getImageUrl(ctx)
          : fallbackImageUrl;

      final duration = getDuration(albumDataNew['duration']);

      final albumResult = AlbumResultSimple.named(
        id: albumDataNew['id'] as String,
        name: albumDataNew['name'] as String,
        title: albumDataNew['title'] as String,
        artistName: albumDataNew['artist'] as String,
        artistId: albumDataNew['artistId'] as String,
        coverArtId: coverArtId,
        coverArtLink: coverArtLink,
        year: albumDataNew['year'] as int? ?? 0,
        duration: duration,
        songCount: albumDataNew['songCount'] as int? ?? 0,
        createdAt: DateTime.parse(albumDataNew['created'] as String),
        isVideo: albumDataNew['isVideo'] as bool,
        parent: albumDataNew['parent'] as String,
        playCount: albumDataNew['playcount'] as int? ?? 0,
        starredAt: parseDateTime(albumDataNew['starred'] as String?),
      );

      return albumResult;
    }).toList();

    final songs = List<Map<String, dynamic>>.from(songField).map((songData) {
      return SongResult.fromJson(songData, ctx);
    }).toList()
      ..sort((a, b) => a.starredAt!.compareTo(b.starredAt!));

    final getStarred2Result = GetStarred2Result(
      albums: albums,
      songs: songs,
      lastModified: lastModified,
    );

    return SubsonicResponse(
      ResponseStatus.ok,
      data['subsonic-response']['version'] as String,
      getStarred2Result,
    );
  }
}
