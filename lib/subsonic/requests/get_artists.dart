import 'dart:convert';

import 'package:subsound/subsonic/requests/get_cover_art.dart';

import '../base_request.dart';
import '../context.dart';
import '../response.dart';

class GetArtistsData {
  final String ignoredArticles;
  final List<ArtistIndexEntry> index;

  GetArtistsData(this.ignoredArticles, List<ArtistIndexEntry> index)
      : this.index = List.unmodifiable(index);

  @override
  String toString() {
    return 'GetArtistsData{ignoredArticles: $ignoredArticles, index: $index}';
  }
}

class ArtistIndexEntry {
  final String name;
  final List<Artist> artist;

  ArtistIndexEntry(this.name, List<Artist> artist)
      : this.artist = List.unmodifiable(artist);

  @override
  String toString() {
    return 'ArtistIndexEntry{name: $name, artist: $artist}';
  }
}

class Artist {
  final String id;
  final String name;
  final String coverArtId;
  final String coverArtLink;
  final int albumCount;

  Artist({
    required this.id,
    required this.name,
    required this.coverArtId,
    required this.coverArtLink,
    required this.albumCount,
  });

  @override
  String toString() {
    return 'Artist{id: $id, name: $name, coverArt: $coverArtId, albumCount: $albumCount}';
  }
}

class GetArtistsRequest extends BaseRequest<GetArtistsData> {
  final String? musicFolderId;

  GetArtistsRequest({this.musicFolderId});

  @override
  String get sinceVersion => "1.8.0";

  @override
  Future<SubsonicResponse<GetArtistsData>> run(SubsonicContext ctx) async {
    var uri = ctx.endpoint.resolve("rest/getArtists");
    uri = ctx.applyUriParams(uri);
    if (musicFolderId != null) {
      uri = uri.replace(
          queryParameters: Map.from(uri.queryParameters)
            ..['musicFolderId'] = '$musicFolderId');
    }

    final response = await ctx.client.get(uri, headers: {
      "Accept-Charset": "utf-8",
      "Accept": "application/json; charset=utf-8;",
    });

    final data =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    final status = data['subsonic-response']['status'];
    if (status == 'failed') {
      throw StateError('${data['subsonic-response']['error']['code']}');
    }

    final artists = data['subsonic-response']['artists'] ?? {};
    final String? ignoredArticles = artists['ignoredArticles'];
    final List<dynamic> artistIndex = artists['index'] ?? [];

    final out = GetArtistsData(
      ignoredArticles ?? '',
      artistIndex.map((entry) {
        return ArtistIndexEntry(
          entry['name'] ?? '',
          (entry['artist'] as List)
              .map((artist) {
                String artistImageUrl = artist["artistImageUrl"] ?? '';
                final String coverArt = artist['coverArt'] ?? '';
                final coverArtLink = artistImageUrl.isNotEmpty
                    ? artistImageUrl
                    : coverArt.isNotEmpty
                        ? GetCoverArt(coverArt).getImageUrl(ctx)
                        : "https://lastfm.freetls.fastly.net/i/u/174s/2a96cbd8b46e442fc41c2b86b821562f.png";

                final String coverArtId =
                    coverArt.isNotEmpty ? coverArt : coverArtLink;
                final String artistName = artist['name'] ?? '';

                return Artist(
                  id: artist['id'],
                  name: artistName,
                  coverArtId: coverArtId,
                  coverArtLink: coverArtLink,
                  albumCount: artist['albumCount'] ?? 0,
                );
              })
              .map((element) => element)
              .toList(),
        );
      }).toList(),
    );

    return SubsonicResponse(
        ResponseStatus.ok, data['subsonic-response']['version'], out);
  }
}
