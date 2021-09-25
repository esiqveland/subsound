import 'dart:convert';

import '../base_request.dart';
import '../context.dart';
import '../response.dart';

class GetArtistsData {
  final String ignoredArticles;
  final List<ArtistIndexEntry> index;

  GetArtistsData(this.ignoredArticles, List<ArtistIndexEntry> index)
      : index = List.unmodifiable(index);

  @override
  String toString() {
    return 'GetArtistsData{ignoredArticles: $ignoredArticles, index: $index}';
  }
}

class ArtistIndexEntry {
  final String name;
  final List<Artist> artist;

  ArtistIndexEntry(this.name, List<Artist> artist)
      : artist = List.unmodifiable(artist);

  @override
  String toString() {
    return 'ArtistIndexEntry{name: $name, artist: $artist}';
  }
}

class Artist {
  final String id;
  final String name;
  final String coverArt;
  final int albumCount;

  Artist(this.id, this.name, this.coverArt, this.albumCount);

  @override
  String toString() {
    return 'Artist{id: $id, name: $name, coverArt: $coverArt, albumCount: $albumCount}';
  }
}

class GetIndexesRequest extends BaseRequest<GetArtistsData> {
  final String? musicFolderId;

  GetIndexesRequest({this.musicFolderId});

  @override
  String get sinceVersion => "1.8.0";

  @override
  Future<SubsonicResponse<GetArtistsData>> run(SubsonicContext ctx) async {
    var uri = ctx.endpoint.resolve("rest/getIndexes");
    uri = ctx.applyUriParams(uri);

    if (musicFolderId != null) {
      uri = uri.replace(
          queryParameters: Map.from(uri.queryParameters)
            ..['musicFolderId'] = '$musicFolderId');
    }
    final response = await ctx.client.get(uri);

    final data =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    final status = data['subsonic-response']['status'];
    if (status == 'failed') {
      throw StateError('${data['subsonic-response']['error']['code']}');
    }

    //final indexes = data['subsonic-response']['indexes'] as Map;

    throw StateError("Not implemented yet.");

    // indexes.keys.map((e) => null).toList();
    //
    // final out = GetArtistsData(
    //   indexes['ignoredArticles'],
    //   (indexes['index'] as List).map((entry) {
    //     return ArtistIndexEntry(
    //       entry['name'],
    //       (entry['artist'] as List).map((artist) {
    //         return Artist(
    //           artist['id'],
    //           artist['name'],
    //           artist['coverArt'],
    //           artist['albumCount'],
    //         );
    //       }).toList(),
    //     );
    //   }).toList(),
    // );
    //
    // return SubsonicResponse(ResponseStatus.ok, data['version'], out);
  }
}
