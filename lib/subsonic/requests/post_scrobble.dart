import 'dart:convert';

import 'package:subsound/subsonic/base_request.dart';
import 'package:subsound/subsonic/context.dart';
import 'package:subsound/subsonic/response.dart';

// Returns an empty <subsonic-response> element on success, so no data:
class ScrobbleResult {}

class PostScrobbleRequest extends BaseRequest<ScrobbleResult> {
  final String id;
  final DateTime playedAt;
  // Whether this is a "submission" or a "now playing" notification.
  final bool submission;

  PostScrobbleRequest(
    this.id, {
    DateTime? playedAt,
    this.submission = true,
  }) : playedAt = playedAt ?? DateTime.now();

  @override
  String get sinceVersion => "1.5.0";

  @override
  Future<SubsonicResponse<ScrobbleResult>> run(SubsonicContext ctx) async {
    final resp = await ctx.client.get(ctx.buildRequestUri(
      'scrobble',
      params: {
        'id': id,
        'time': "${playedAt.millisecondsSinceEpoch}",
        'submission': submission.toString(),
      },
    ));
    final data =
        jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;

    if (data['subsonic-response']['status'] != 'ok') {
      throw Exception("status=${resp.statusCode} data=${data}");
    }

    if (resp.statusCode == 200) {
      return SubsonicResponse(
        ResponseStatus.ok,
        ctx.version,
        ScrobbleResult(),
      );
    } else {
      throw Exception("status=${resp.statusCode} data=${data}");
    }
  }
}
