import 'dart:developer';

import 'package:http/http.dart';
import 'package:meta/meta.dart';
import 'token.dart';

class SubsonicContext {
  final Client client;
  final String serverId;
  final String name;
  final Uri endpoint;
  final String version = '1.15.0';
  final String user;
  final String _pass;

  SubsonicContext({
    @required this.serverId,
    @required this.name,
    @required this.endpoint,
    @required this.user,
    @required String pass,
  })  : _pass = pass,
        token = AuthToken(pass),
        client = defaultClient();

  static Client defaultClient() {
    return LoggingClient(new Client());
  }

  factory SubsonicContext.parse(Map<String, dynamic> row) {
    return SubsonicContext(
      serverId: row['id'],
      name: row['name'],
      endpoint: Uri.parse(row['uri']),
      user: row['user'],
      pass: row['pass'],
    );
  }

  Map<String, dynamic> get serialized => {
        'id': serverId,
        'name': name,
        'uri': endpoint.toString(),
        'user': user,
        'pass': _pass,
      };

  // AuthToken get token => AuthToken(_pass);
  final AuthToken token;

  Uri buildRequestUri(String name, {Map<String, String> params}) {
    var uri = endpoint.resolve("rest/$name");
    uri = uri.replace(
        queryParameters: Map.from(uri.queryParameters)..addAll(params ?? {}));
    // print(uri);
    return applyUriParams(uri);
  }

  Uri applyUriParams(Uri uri) {
    final t = token;
    final params = {
      'v': version,
      'u': user,
      't': t.token,
      's': t.salt,
      'c': 'dartsonic',
      'f': 'json'
    };
    return uri.replace(
      queryParameters: Map.from(uri.queryParameters)..addAll(params),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubsonicContext &&
          runtimeType == other.runtimeType &&
          serverId == other.serverId &&
          name == other.name &&
          endpoint == other.endpoint &&
          version == other.version &&
          user == other.user &&
          _pass == other._pass;

  @override
  int get hashCode =>
      serverId.hashCode ^
      name.hashCode ^
      endpoint.hashCode ^
      version.hashCode ^
      user.hashCode ^
      _pass.hashCode;
}

class LoggingClient extends BaseClient {
  final Client _delegate;

  LoggingClient(this._delegate);

  @override
  Future<StreamedResponse> send(BaseRequest req) {
    final start = DateTime.now();
    log('http:client:${start.millisecondsSinceEpoch}:${req.method}:${req.url.toString()}: start');
    return _delegate.send(req).then((res) {
      final elapsed = DateTime.now().difference(start);
      log('http:client:${start.millisecondsSinceEpoch}:${req.method}:${req.url.toString()}: ${res.statusCode} ${res.reasonPhrase} took ${elapsed.inMilliseconds}ms');
      return res;
    }).catchError((err) {
      final elapsed = DateTime.now().difference(start);
      log('http:client:${start.millisecondsSinceEpoch}:${req.method}:${req.url.toString()}: ERROR took ${elapsed.inMilliseconds}ms', error: err);
      return Future.error(err);
    });
  }
}
