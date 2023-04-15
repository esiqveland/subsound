import 'dart:convert';

import 'package:subsound/subsonic/base_request.dart';
import 'package:subsound/subsonic/context.dart';
import 'package:subsound/subsonic/requests/get_playlist.dart';
import 'package:subsound/subsonic/requests/get_starred2.dart';
import 'package:subsound/subsonic/response.dart';

class GetPlaylistsResult {
  final List<PlaylistResult> playlists;

  GetPlaylistsResult(this.playlists);
}

bool? parseBool(dynamic val) {
  if (val == null) {
    return null;
  }
  if (val is bool) {
    return val;
  } else if (val is String) {
    return "true" == val.toLowerCase();
  } else {
    return null;
  }
}

class GetPlaylists extends BaseRequest<GetPlaylistsResult> {
  GetPlaylists();

  @override
  String get sinceVersion => '1.0.0';

  @override
  Future<SubsonicResponse<GetPlaylistsResult>> run(SubsonicContext ctx) async {
    final response = await ctx.client.get(ctx.buildRequestUri('getPlaylists'));

    final data =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    if (data['subsonic-response']['status'] != 'ok') {
      throw Exception(data);
    }

    final rawData =
        (data['subsonic-response']['playlists']['playlist'] ?? []) as List;

    final List<PlaylistResult> playlists = rawData
        .map((p) => PlaylistResult(
              id: p['id'].toString(),
              name: p['name'] as String? ?? '',
              comment: p['comment'] as String? ?? '',
              songCount: p['songCount'] as int? ?? 0,
              duration: Duration(seconds: p['duration'] as int? ?? 0),
              isPublic: parseBool(p['public']) ?? false,
              owner: p['owner'] as String? ?? '',
              changedAt:
                  parseDateTime(p['changed'] as String?) ?? DateTime.now(),
              createdAt:
                  parseDateTime(p['created'] as String?) ?? DateTime.now(),
            ))
        .toList();

    final res = GetPlaylistsResult(playlists);

    return SubsonicResponse(
      ResponseStatus.ok,
      data['subsonic-response']['version'] as String,
      res,
    );
  }
}
