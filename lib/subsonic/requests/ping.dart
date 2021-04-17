import 'dart:convert';

import '../subsonic.dart';

class Ping extends BaseRequest<String> {
  @override
  String get sinceVersion => "1.0.0";

  @override
  Future<SubsonicResponse<String>> run(SubsonicContext ctx) async {
    final response = await ctx.client.get(ctx.buildRequestUri('ping'));
    if (response.statusCode != 200) {
      return Future.error('Ping received status ${response.statusCode}');
    }
    final bodyStr = utf8.decode(response.bodyBytes);
    final data = jsonDecode(bodyStr) as Map<String, dynamic>;
    if (data['subsonic-response']['status'] == 'ok') {
      return SubsonicResponse(ResponseStatus.ok, ctx.version, bodyStr);
    } else {
      return SubsonicResponse(ResponseStatus.failed, ctx.version, bodyStr);
    }
  }
}
