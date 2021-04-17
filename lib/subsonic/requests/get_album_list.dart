import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:subsound/subsonic/subsonic.dart';

enum GetAlbumListType {
  alphabeticalByName,
  alphabeticalByArtist,
  random,
  newest,
  highest,
  starred,
  frequent,
  recent,
  byYear,
  byGenre,
}

class GetAlbumList extends BaseRequest<List<Album>> {
  final GetAlbumListType type;
  final int? size;
  final int? offset;
  final String? musicFolderId;

  GetAlbumList({
    required this.type,
    this.size,
    this.offset,
    this.musicFolderId,
  });

  @override
  String get sinceVersion => '1.2.0';

  @override
  Future<SubsonicResponse<List<Album>>> run(SubsonicContext ctx) async {
    final response = await ctx.client.get(ctx.buildRequestUri(
      'getAlbumList',
      params: {
        'type': describeEnum(type),
        if (size != null) 'size': size!.toString(),
        if (offset != null) 'offset': offset!.toString(),
        if (musicFolderId != null) 'musicFolderId': musicFolderId!,
      },
    ));

    final json =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final data = json['subsonic-response'];
    if (data['status'] != 'ok') {
      throw Exception(data);
    }

    return SubsonicResponse(
      ResponseStatus.ok,
      ctx.version,
      (data['albumList']['album'] as List)
          .map((album) => Album.parse(ctx, album as Map<String, dynamic>))
          .toList(),
    );
  }
}
