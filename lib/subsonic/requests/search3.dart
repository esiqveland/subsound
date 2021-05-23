import 'dart:convert';

import 'package:subsound/subsonic/requests/get_album.dart';
import 'package:subsound/subsonic/subsonic.dart';

class Search3Result {
  final List<SongResult> songs;

  Search3Result(this.songs);
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

    var list = data['searchResult3']['song'] as List<dynamic>;

    final List<SongResult> songs = List<Map<String, dynamic>>.from(list)
        .map((song) => SongResult.fromJson(song, ctx))
        .toList();

    return SubsonicResponse(
      ResponseStatus.ok,
      ctx.version,
      Search3Result(songs),
    );
  }
}
