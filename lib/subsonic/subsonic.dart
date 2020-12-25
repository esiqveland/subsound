export 'base_request.dart';
export 'context.dart';
export 'models/models.dart';
export 'response.dart';
export 'token.dart';

enum SubsonicResponseFormat { xml, json, jsonp }

extension FormatToString on SubsonicResponseFormat {
  String serialize() {
    return this == SubsonicResponseFormat.xml
        ? 'xml'
        : this == SubsonicResponseFormat.json
            ? 'json'
            : 'jsonp';
  }
}
