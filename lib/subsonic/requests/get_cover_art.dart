import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:subsound/storage/cache.dart';

import '../subsonic.dart';

class GetCoverArt extends BaseRequest<Uint8List> {
  final String id;
  final int size;

  GetCoverArt(this.id, {this.size});

  @override
  String get sinceVersion => '1.0.0';

  Uri _getImageUri(SubsonicContext ctx) {
    var uri = ctx.endpoint.resolve("rest/getCoverArt");
    uri = ctx.buildRequestUri(
      'getCoverArt',
      params: {
        'id': '$id',
        if (size != null) 'size': '$size',
      },
    );

    return uri;
  }

  String getImageUrl(SubsonicContext ctx) => _getImageUri(ctx).toString();

  static Stream<FileInfo> loadWithCache(
    String url, {
    String cacheKey,
    int height,
    int width,
  }) {
    final info = ArtworkCacheManager().getImageFile(
      url,
      withProgress: false,
      key: cacheKey,
      maxHeight: height,
      maxWidth: width,
    );
    return info.map((event) {
      if (event is FileInfo) {
        return event as FileInfo;
      } else {
        log('error: event is of type DownloadProgress');
        throw new StateError('error: event is of type DownloadProgress');
      }
    });
  }

  @override
  Future<SubsonicResponse<Uint8List>> run(SubsonicContext ctx) async {
    final uri = _getImageUri(ctx);

    final resp = await loadWithCache(
      uri.toString(),
      cacheKey: id,
      height: size,
      width: size,
    ).single.then((value) => value as FileInfo);

    final body = await resp.file.readAsBytes();
    return SubsonicResponse(ResponseStatus.ok, ctx.version, body);
  }
}
