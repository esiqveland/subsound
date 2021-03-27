import 'dart:convert';

import 'package:subsound/subsonic/requests/get_album.dart';
import 'package:subsound/subsonic/requests/get_artist.dart';
import 'package:subsound/subsonic/requests/get_cover_art.dart';
import 'package:subsound/subsonic/requests/stream_id.dart';
import 'package:subsound/utils/duration.dart';

import '../base_request.dart';
import '../subsonic.dart';

class GetStarred2Result {
  final List<AlbumResultSimple> albums;
  final List<SongResult> songs;

  GetStarred2Result({required this.albums, required this.songs});
}

class GetStarred2 extends BaseRequest<GetStarred2Result> {
  GetStarred2();

  @override
  String get sinceVersion => '1.8.0';

  @override
  Future<SubsonicResponse<GetStarred2Result>> run(SubsonicContext ctx) async {
    final response = await ctx.client.get(ctx.buildRequestUri('getStarred2'));

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (data['subsonic-response']['status'] != 'ok') {
      throw StateError(data);
    }

    final starred2Field = data['subsonic-response']['starred2'];
    final albumField = (starred2Field["album"] ?? []) as List;
    final songField = (starred2Field["song"] ?? []) as List;

    final albums = albumField.map((albumDataNew) {
      final coverArtId = albumDataNew['coverArt'];

      final coverArtLink = coverArtId != null
          ? GetCoverArt(coverArtId).getImageUrl(ctx)
          : FallbackImageUrl;

      //log('coverArtLink=$coverArtLink');

      final duration = getDuration(albumDataNew['duration']);

      final albumResult = AlbumResultSimple.named(
        id: albumDataNew['id'],
        name: albumDataNew['name'],
        title: albumDataNew['title'],
        artistName: albumDataNew['artist'],
        artistId: albumDataNew['artistId'],
        coverArtId: coverArtId,
        coverArtLink: coverArtLink,
        year: albumDataNew['year'] ?? 0,
        duration: duration,
        songCount: albumDataNew['songCount'] ?? 0,
        createdAt: DateTime.parse(albumDataNew['created']),
        isVideo: albumDataNew['isVideo'],
        parent: albumDataNew['parent'],
        playCount: albumDataNew['playcount'],
      );

      return albumResult;
    }).toList();

    final songs = songField.map((songData) {
      final songArtId = songData['coverArt'];
      final coverArtLink = GetCoverArt(songArtId).getImageUrl(ctx);
      final duration = getDuration(songData['duration']);

      final id = songData['id'];
      final playUrl = StreamItem(id).getDownloadUrl(ctx);

      return SongResult(
        id: id,
        playUrl: playUrl,
        parent: songData['parent'],
        title: songData['title'],
        artistName: songData['artist'],
        artistId: songData['artistId'],
        albumName: songData['album'],
        albumId: songData['albumId'],
        coverArtId: songArtId,
        coverArtLink: coverArtLink,
        year: songData['year'] ?? 0,
        duration: duration,
        isVideo: songData['isVideo'] ?? false,
        createdAt: DateTime.parse(songData['created']),
        type: songData['type'],
        bitRate: songData['bitRate'] ?? 0,
        trackNumber: songData['track'] ?? 0,
        fileSize: songData['size'] ?? 0,
        starred: songData['starred'] ?? false,
        contentType: songData['contentType'] ?? '',
        suffix: songData['suffix'] ?? '',
      );
    }).toList();

    final getStarred2Result = GetStarred2Result(
      albums: albums,
      songs: songs,
    );

    return SubsonicResponse(
      ResponseStatus.ok,
      data['subsonic-response']['version'],
      getStarred2Result,
    );
  }
}
