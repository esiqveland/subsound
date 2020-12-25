import 'dart:convert';

import '../subsonic.dart';

class Ping extends BaseRequest<void> {
  @override
  String get sinceVersion => "1.0.0";

  @override
  Future<SubsonicResponse<void>> run(SubsonicContext ctx) async {
    final response = await ctx.client.get(ctx.buildRequestUri('ping'));
    if (response.statusCode != 200)
      return Future.error('Ping received status ${response.statusCode}');

    final data =
        jsonDecode(utf8.decode(response.bodyBytes))['subsonic-response'];
    if (data['status'] == 'ok') {
      return SubsonicResponse(ResponseStatus.ok, ctx.version, data);
    } else {
      return SubsonicResponse(ResponseStatus.failed, ctx.version, null);
    }
  }
}
