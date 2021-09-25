export 'base_request.dart';
export 'context.dart';
export 'models/models.dart';
export 'response.dart';
export 'token.dart';

const fallbackImageUrl =
    'https://lastfm.freetls.fastly.net/i/u/174s/2a96cbd8b46e442fc41c2b86b821562f.png';

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
