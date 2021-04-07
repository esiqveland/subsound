// TODO:
// - edit server settings
// - clear artwork cache
// - clear file cache

import 'package:flutter/material.dart';
import 'package:subsound/storage/cache.dart';
import 'package:subsound/utils/utils.dart';

class ArtworkCacheStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("Artwork Cache"),
        Text("Not implemented"),
      ],
    );
  }
}

class DownloadCacheStatsWidget extends StatelessWidget {
  final Future<CacheStats> stats;

  DownloadCacheStatsWidget({Key? key, required this.stats}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CacheStats>(
      future: stats,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          CacheStats data = snapshot.data!;
          return Column(
            children: [
              Text("Items: ${data.itemCount}"),
              Text("Storage used: ${formatFileSize(data.totalSize)}"),
            ],
          );
        } else {
          return Text("Calculating...");
        }
      },
    );
  }
}

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DownloadCacheStatsWidget(
          stats: DownloadCacheManager().getStats(),
        ),
        ArtworkCacheStats(),
      ],
    );
  }
}
