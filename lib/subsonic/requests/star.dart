import 'dart:convert';

import 'package:subsound/subsonic/base_request.dart';
import 'package:subsound/subsonic/context.dart';
import 'package:subsound/subsonic/response.dart';

class StarResponse {}

class SongId extends ItemId {
  final String songId;
  SongId({required this.songId});

  @override
  String get getFieldName => "id";

  @override
  String get getId => songId;
}

class ArtistId extends ItemId {
  final String artistId;
  ArtistId({required this.artistId});

  @override
  String get getFieldName => "artistId";

  @override
  String get getId => artistId;
}

class AlbumId extends ItemId {
  final String albumId;
  AlbumId({required this.albumId});

  @override
  String get getFieldName => "albumId";

  @override
  String get getId => albumId;
}

abstract class ItemId {
  String get getFieldName;
  String get getId;
}

class StarItem extends BaseRequest<StarResponse> {
  final ItemId id;
  StarItem({required this.id});

  @override
  Future<SubsonicResponse<StarResponse>> run(SubsonicContext ctx) async {
    final uri = ctx.buildRequestUri("star", params: {
      id.getFieldName: id.getId,
    });

    final response = await ctx.client.get(uri);
    if (response.statusCode != 200) {
      throw StateError("${response.statusCode}: " + response.body);
    }

    final json =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final data = json['subsonic-response'];

    if (data['status'] != 'ok') {
      throw StateError("${response.statusCode}: " + response.body);
    }

    return SubsonicResponse(ResponseStatus.ok, ctx.version, StarResponse());
  }

  @override
  String get sinceVersion => "1.8.0";
}

class UnstarResponse {}

class UnstarItem extends BaseRequest<UnstarResponse> {
  final ItemId id;
  UnstarItem({required this.id});

  @override
  Future<SubsonicResponse<UnstarResponse>> run(SubsonicContext ctx) async {
    final uri = ctx.buildRequestUri("unstar", params: {
      id.getFieldName: id.getId,
    });

    final response = await ctx.client.get(uri);
    if (response.statusCode != 200) {
      throw StateError("${response.statusCode}: " + response.body);
    }

    final json =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final data = json['subsonic-response'];

    if (data['status'] != 'ok') {
      throw StateError("${response.statusCode}: " + response.body);
    }

    return SubsonicResponse(ResponseStatus.ok, ctx.version, UnstarResponse());
  }

  @override
  String get sinceVersion => "1.8.0";
}
