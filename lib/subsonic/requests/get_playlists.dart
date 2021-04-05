import 'dart:convert';

import 'package:subsound/subsonic/base_request.dart';
import 'package:subsound/subsonic/context.dart';
import 'package:subsound/subsonic/requests/get_starred2.dart';
import 'package:subsound/subsonic/response.dart';

class GetPlaylistsResult {
  final List<PlaylistResult> playlists;

  GetPlaylistsResult(this.playlists);
}

class PlaylistResult {
  final String id;
  final String name;
  final String comment;
  final int songCount;
  final Duration duration;
  final bool isPublic;
  final String owner;
  final DateTime createdAt;
  final DateTime changedAt;

  PlaylistResult({
    required this.id,
    required this.name,
    required this.comment,
    required this.songCount,
    required this.duration,
    required this.isPublic,
    required this.owner,
    required this.createdAt,
    required this.changedAt,
  });
}

class GetPlaylists extends BaseRequest<GetPlaylistsResult> {
  GetPlaylists();

  @override
  String get sinceVersion => '1.0.0';

  @override
  Future<SubsonicResponse<GetPlaylistsResult>> run(SubsonicContext ctx) async {
    final response = await ctx.client.get(ctx.buildRequestUri('getPlaylists'));

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (data['subsonic-response']['status'] != 'ok') {
      throw StateError(data);
    }

    final rawData =
        (data['subsonic-response']['playlists']['playlist'] ?? []) as List;

    final List<PlaylistResult> playlists = rawData
        .map((p) => PlaylistResult(
              id: p['id'],
              name: p['name'] ?? '',
              comment: p['comment'] ?? '',
              songCount: p['songCount'] ?? 0,
              duration: Duration(seconds: p['duration'] ?? 0),
              isPublic: p['public'] ?? false,
              owner: p['owner'] ?? '',
              changedAt: parseDateTime(p['changed'])!,
              createdAt: parseDateTime(p['created'])!,
            ))
        .toList();

    final res = GetPlaylistsResult(playlists);

    return SubsonicResponse(
      ResponseStatus.ok,
      data['subsonic-response']['version'],
      res,
    );
  }
}
