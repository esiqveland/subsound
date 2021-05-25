import 'dart:convert';

import 'package:subsound/subsonic/requests/get_album.dart';
import 'package:subsound/subsonic/requests/get_artist.dart';
import 'package:subsound/subsonic/requests/get_artists.dart';
import 'package:subsound/subsonic/subsonic.dart';

class Search3Result {
  final List<SongResult> songs;
  final List<AlbumResultSimple> albums;
  final List<Artist> artists;

  Search3Result(this.songs, this.albums, this.artists);
}

class CountOffset {
  final int count, offset;

  const CountOffset({
    required this.count,
    this.offset = 0,
  });
}

class Search3Request extends BaseRequest<Search3Result> {
  @override
  String get sinceVersion => '1.8.0';

  final String query;

  final CountOffset? artist, album, song;
  final String? musicFolderId;

  Search3Request(
    this.query, {
    this.artist,
    this.album,
    this.song,
    this.musicFolderId,
  });

  @override
  Future<SubsonicResponse<Search3Result>> run(SubsonicContext ctx) async {
    final response = await ctx.client.get(ctx.buildRequestUri(
      'search3',
      params: {'query': query}
        ..addAll(
          artist != null
              ? {
                  'artistCount': '${artist!.count}',
                  'artistOffset': '${artist!.offset}'
                }
              : {},
        )
        ..addAll(
          album != null
              ? {
                  'albumCount': '${album!.count}',
                  'albumOffset': '${album!.offset}'
                }
              : {},
        )
        ..addAll(
          song != null
              ? {'songCount': '${song!.count}', 'songOffset': '${song!.offset}'}
              : {},
        ),
    ));

    final json =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final data = json['subsonic-response'];

    if (data['status'] != 'ok') {
      throw Exception(data);
    }

    var listArtist = data['searchResult3']['artist'] as List<dynamic>;
    final List<Artist> artists = List<Map<String, dynamic>>.from(listArtist)
        .map((artistData) => Artist.fromJson(artistData, ctx))
        .toList();

    var listAlbum = data['searchResult3']['album'] as List<dynamic>;
    final List<AlbumResultSimple> albums =
        List<Map<String, dynamic>>.from(listAlbum)
            .map((song) => AlbumResultSimple.fromJson(song, ctx))
            .toList();

    var list = data['searchResult3']['song'] as List<dynamic>;
    final List<SongResult> songs = List<Map<String, dynamic>>.from(list)
        .map((song) => SongResult.fromJson(song, ctx))
        .toList();

    return SubsonicResponse(
      ResponseStatus.ok,
      ctx.version,
      Search3Result(songs, albums, artists),
    );
  }
}
