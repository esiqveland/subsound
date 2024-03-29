import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:subsound/storage/cache.dart';
import 'package:subsound/subsonic/requests/get_cover_art.dart';

const fallbackImageUrl =
    'https://lastfm.freetls.fastly.net/i/u/174s/2a96cbd8b46e442fc41c2b86b821562f.png';

class CoverArtImage extends StatelessWidget {
  final String? id;
  final String? url;
  final double height;
  final double width;
  final BoxFit? fit;

  const CoverArtImage(
    this.url, {
    Key? key,
    String? id,
    this.height = 48.0,
    this.width = 48.0,
    this.fit,
  })  : id = id ?? url,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    if (id == null || id!.startsWith("http")) {
      //log('broken cache id for CoverArtImage: id=$id url=$url');
    }
    return CachedNetworkImage(
      imageUrl: url ?? fallbackImageUrl,
      height: height,
      width: width,
      //placeholderFadeInDuration: ,
      cacheManager: ArtworkCacheManager(),
      fit: fit,
      cacheKey: id,

      // progressIndicatorBuilder: (context, url, downloadProgress) =>
      //     CircularProgressIndicator(value: downloadProgress.progress),
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
    Key? key,
    String? id,
    this.height = 48.0,
    this.width = 48.0,
  })  : id = id ?? url,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FileInfo>(
      stream: GetCoverArt.loadWithCache(
        url,
        height: height.toInt(),
        width: width.toInt(),
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
            snapshot.data!.file,
            width: width,
            height: height,
          );
        }
      },
    );
  }
}
