import 'dart:developer';
import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
// ignore: implementation_imports
import 'package:flutter_cache_manager/src/storage/file_system/file_system_io.dart'
    as fsio;
import 'package:http/http.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:subsound/subsonic/context.dart';

class ArtworkCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'artworkCacheKey';

  static ArtworkCacheManager? _instance;

  factory ArtworkCacheManager() {
    _instance ??= ArtworkCacheManager._();
    return _instance!;
  }

  ArtworkCacheManager._()
      : super(
          Config(
            key,
            stalePeriod: const Duration(days: 700),
            maxNrOfCacheObjects: 1000,
            repo: JsonCacheInfoRepository(databaseName: key),
            fileService: HttpFileService(
              httpClient: LoggingClient(Client()),
            ),
            fileSystem: fsio.IOFileSystem(key),
          ),
        );
}

class SongMetadata {
  final String songId;
  final String songUrl;
  final String fileExtension;
  final int fileSize;
  final String contentType;

  SongMetadata({
    required this.songId,
    required this.songUrl,
    required this.fileExtension,
    required this.fileSize,
    required this.contentType,
  });
}

class PathInfo {
  final FileSystemEntity entity;
  final FileStat stat;

  PathInfo(this.entity, this.stat);
}

class DownloadCacheManager extends CacheManager {
  static const key = 'downloadCacheKey';

  static DownloadCacheManager? _instance;

  factory DownloadCacheManager() {
    _instance ??= DownloadCacheManager._();
    return _instance!;
  }

  Future<Directory> _getCacheDir() async {
    final dir = await getTemporaryDirectory();
    final cacheDir = Directory(p.join(dir.path, 'cache'));
    return cacheDir;
  }

  Future<File> getCachedSongFile(SongMetadata meta) async {
    final dir = await _getCacheDir();
    return File(p.joinAll([
      dir.path,
      "songs",
      meta.songId,
      meta.fileExtension,
    ]));
  }

  Future<CacheStats> getStats() async {
    final dir = await _getCacheDir();

    int items = 0;
    int size = 0;

    await dir
        .list(recursive: true)
        .where((event) => event is File)
        .where((event) => !event.path.endsWith(".part"))
        .asyncMap((event) => event.stat().then((stat) => PathInfo(event, stat)))
        .where((info) => info.stat.type == FileSystemEntityType.file)
        .forEach((PathInfo i) {
      log('PathInfo=$i');
      items = items + 1;
      size = size + i.stat.size;
    });

    return CacheStats(
      itemCount: items,
      totalSize: size,
    );
  }

  DownloadCacheManager._()
      : super(
          Config(
            key,
            stalePeriod: const Duration(days: 7000),
            maxNrOfCacheObjects: 20000,
            repo: JsonCacheInfoRepository(databaseName: key),
            fileService: HttpFileService(
              httpClient: LoggingClient(Client()),
            ),
            fileSystem: fsio.IOFileSystem(key),
          ),
        );
}

class CacheStats {
  final int itemCount;
  final int totalSize;

  CacheStats({required this.itemCount, required this.totalSize});
}

// class IOFileSystem implements fs.FileSystem {
//   final Future<Directory> _fileDir;
//
//   IOFileSystem(String key) : _fileDir = createDirectory(key);
//
//   static Future<Directory> createDirectory(String key) async {
//     var baseDir = await getTemporaryDirectory();
//     var path = p.join(baseDir.path, key);
//
//     var fs = const LocalFileSystem();
//     var directory = fs.directory((path));
//     await directory.create(recursive: true);
//     return directory;
//   }
//
//   @override
//   Future<File> createFile(String name) async {
//     assert(name != null);
//     return (await _fileDir).childFile(name);
//   }
// }
