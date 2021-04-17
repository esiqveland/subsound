import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:subsound/subsonic/subsonic.dart';

import './get_album_list.dart';

class GetAlbumList2 extends BaseRequest<List<Album>> {
  final GetAlbumListType type;
  final int? size;
  final int? offset;
  final String? musicFolderId;

  GetAlbumList2({
    required this.type,
    this.size,
    this.offset,
    this.musicFolderId,
  });

  @override
  String get sinceVersion => '1.8.0';

  @override
  Future<SubsonicResponse<List<Album>>> run(SubsonicContext ctx) async {
    final response = await ctx.client.get(ctx.buildRequestUri(
      'getAlbumList2',
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

    var albumListData = data['albumList2']['album'];
    if (albumListData == null) {
      return SubsonicResponse(ResponseStatus.ok, ctx.version, []);
    } else {
      return SubsonicResponse(
        ResponseStatus.ok,
        ctx.version,
        (albumListData as List)
            .map((album) => Album.parse(ctx, album as Map<String, dynamic>))
            .toList(),
      );
    }
  }
}
