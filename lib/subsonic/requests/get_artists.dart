import 'dart:convert';

import 'package:subsound/subsonic/requests/get_cover_art.dart';
import 'package:subsound/subsonic/subsonic.dart';

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

  static Artist fromJson(Map<String, dynamic> artist, SubsonicContext ctx) {
    String artistImageUrl = artist["artistImageUrl"] as String? ?? '';
    final String coverArt = artist['coverArt'] as String? ?? '';
    final coverArtLink = artistImageUrl.isNotEmpty
        ? artistImageUrl
        : coverArt.isNotEmpty
            ? GetCoverArt(coverArt).getImageUrl(ctx)
            : fallbackImageUrl;

    final String coverArtId = coverArt.isNotEmpty ? coverArt : coverArtLink;
    final String artistName = artist['name'] as String? ?? '';

    return Artist(
      id: artist['id'].toString(),
      name: artistName,
      coverArtId: coverArtId,
      coverArtLink: coverArtLink,
      albumCount: artist['albumCount'] as int? ?? 0,
    );
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
    final String? ignoredArticles = artists['ignoredArticles'] as String?;
    final List<dynamic> artistIndex = artists['index'] as List<dynamic>? ?? [];

    final out = GetArtistsData(
      ignoredArticles ?? '',
      artistIndex.map((entry) {
        var aList = entry['artist'] as List<dynamic>;

        return ArtistIndexEntry(
          entry['name'] as String? ?? '',
          List<Map<String, dynamic>>.from(aList)
              .map((artist) => Artist.fromJson(artist, ctx))
              .map((element) => element)
              .toList(),
        );
      }).toList(),
    );

    return SubsonicResponse(
      ResponseStatus.ok,
      data['subsonic-response']['version'] as String,
      out,
    );
  }
}
