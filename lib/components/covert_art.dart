import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:subsound/storage/cache.dart';
import 'package:subsound/subsonic/requests/get_cover_art.dart';

class CoverArtImage extends StatelessWidget {
  final String id;
  final String url;
  final double height;
  final double width;
  final BoxFit fit;

  const CoverArtImage(
    this.url, {
    Key key,
    String id,
    this.height = 48.0,
    this.width = 48.0,
    this.fit,
  })  : this.id = id ?? url,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      height: height,
      width: width,
      //placeholderFadeInDuration: ,
      cacheManager: ArtworkCacheManager(),
      fit: fit,
      // if (this.id != null ) cacheKey: this.id,
      cacheKey: this.id,
      progressIndicatorBuilder: (context, url, downloadProgress) =>
          CircularProgressIndicator(value: downloadProgress.progress),
      errorWidget: (context, url, error) => Icon(Icons.error),
    );
  }
}

class CoverArtImage2 extends StatelessWidget {
  final String id;
  final String url;
  final double height;
  final double width;

  const CoverArtImage2(
    this.url, {
    Key key,
    String id,
    this.height = 48.0,
    this.width = 48.0,
  })  : this.id = id ?? url,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FileInfo>(
      stream: GetCoverArt.loadWithCache(
        url,
        height: height?.toInt(),
        width: width?.toInt(),
      ),
      builder: (context, snapshot) {
        var loading = !snapshot.hasData || snapshot.data is DownloadProgress;

        if (snapshot.hasError) {
          log('error loading image url=$url', error: snapshot.error);
          return Image.asset(
            "assets/images/emptycover.png",
            width: width,
            height: height,
          );
        } else if (loading) {
          return Image.asset(
            "assets/images/emptycover.png",
            width: width,
            height: height,
          );
        } else {
          return Image.file(
            snapshot.data.file,
            width: width,
            height: height,
          );
        }
      },
    );
  }
}
