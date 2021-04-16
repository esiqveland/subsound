import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:subsound/storage/cache.dart';

import '../subsonic.dart';

/// Downloads a given media file. Similar to stream,
/// but this method returns the original media data without transcoding or downsampling.
class StreamItem extends BaseRequest<Uint8List> {
  final String id;
  final int? maxBitRate;

  StreamItem(
    this.id, {
    this.maxBitRate,
  });

  @override
  String get sinceVersion => '1.0.0';

  Uri _getDownloadUri(SubsonicContext ctx) {
    var uri = ctx.endpoint.resolve("rest/stream");
    uri = ctx.buildRequestUri(
      'stream',
      params: {
        'id': '$id',
        if (maxBitRate != null) 'maxBitRate': '$maxBitRate',
      },
    );

    return uri;
  }

  String getDownloadUrl(SubsonicContext ctx) => _getDownloadUri(ctx).toString();

  static Stream<FileInfo> loadWithCache(
    String url, {
    String? cacheKey,
  }) {
    final info = DownloadCacheManager().getFileStream(
      url,
      withProgress: false,
      key: cacheKey,
    );
    return info.map((event) {
      if (event is FileInfo) {
        return event;
      } else {
        log('error: event is of type DownloadProgress');
        throw StateError('error: event is of type DownloadProgress');
      }
    });
  }

  @override
  Future<SubsonicResponse<Uint8List>> run(SubsonicContext ctx) async {
    final uri = _getDownloadUri(ctx);

    final resp = await loadWithCache(
      uri.toString(),
      cacheKey: id,
    ).single;

    final body = await resp.file.readAsBytes();
    return SubsonicResponse(ResponseStatus.ok, ctx.version, body);
  }
}
