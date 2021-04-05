import 'dart:convert';

import 'package:subsound/subsonic/base_request.dart';
import 'package:subsound/subsonic/context.dart';
import 'package:subsound/subsonic/requests/get_starred2.dart';
import 'package:subsound/subsonic/response.dart';

class PlaylistEntry {}

class GetPlaylistResult {
  PlaylistResult playlist;
  //final List<SongResult> entries;
  final List<PlaylistEntry> entries;

  GetPlaylistResult(this.playlist, this.entries);
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

class GetPlaylist extends BaseRequest<GetPlaylistResult> {
  final String id;
  GetPlaylist(this.id);

  @override
  String get sinceVersion => '1.0.0';

  @override
  Future<SubsonicResponse<GetPlaylistResult>> run(SubsonicContext ctx) async {
    final response = await ctx.client.get(ctx.buildRequestUri(
      'getPlaylists',
      params: {
        'id': this.id,
      },
    ));

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (data['subsonic-response']['status'] != 'ok') {
      throw StateError(data);
    }

    final p = data['subsonic-response']['playlist'] ?? {};
    final playlist = PlaylistResult(
      id: p['id'],
      name: p['name'] ?? '',
      comment: p['comment'] ?? '',
      songCount: p['songCount'] ?? 0,
      duration: Duration(seconds: p['duration'] ?? 0),
      isPublic: p['public'] ?? false,
      owner: p['owner'] ?? '',
      changedAt: parseDateTime(p['changed'])!,
      createdAt: parseDateTime(p['created'])!,
    );

    final rawData =
        (data['subsonic-response']['playlist']['entry'] ?? []) as List;

    final List<PlaylistEntry> playlists =
        rawData.map((e) => PlaylistEntry()).toList();

    final res = GetPlaylistResult(playlist, playlists);

    return SubsonicResponse(
      ResponseStatus.ok,
      data['subsonic-response']['version'],
      res,
    );
  }
}
