import 'dart:convert';

import '../subsonic.dart';

class GetRandomSongs extends BaseRequest<List<Song>> {
  final int size;
  final String? genre;
  final String? fromYear;
  final String? toYear;
  final String? musicFolderId;

  GetRandomSongs({
    required this.size,
    this.genre,
    this.fromYear,
    this.toYear,
    this.musicFolderId,
  });

  @override
  String get sinceVersion => "1.2.0";

  @override
  Future<SubsonicResponse<List<Song>>> run(SubsonicContext ctx) async {
    final response = await ctx.client.get(ctx.buildRequestUri(
      "getRandomSongs",
      params: {
        'size': '$size',
      },
    ));

    final data =
        jsonDecode(utf8.decode(response.bodyBytes))['subsonic-response'];

    if (data['status'] != 'ok') throw StateError(data);

    return SubsonicResponse(
      ResponseStatus.ok,
      ctx.version,
      (data['randomSongs']['song'] as List)
          .map(
            (song) => Song.parse(song),
          )
          .toList(),
    );
  }
}
