import 'package:flutter_cache_manager/flutter_cache_manager.dart';
// ignore: implementation_imports
import 'package:flutter_cache_manager/src/storage/file_system/file_system_io.dart'
    as fsio;
import 'package:http/http.dart';
import 'package:subsound/subsonic/context.dart';

class ArtworkCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'artworkCacheKey';

  static ArtworkCacheManager _instance;

  factory ArtworkCacheManager() {
    _instance ??= ArtworkCacheManager._();
    return _instance;
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

class DownloadCacheManager extends CacheManager {
  static const key = 'downloadCacheKey';

  static DownloadCacheManager _instance;

  factory DownloadCacheManager() {
    _instance ??= DownloadCacheManager._();
    return _instance;
  }

  DownloadCacheManager._()
      : super(
          Config(
            key,
            stalePeriod: const Duration(days: 7000),
            maxNrOfCacheObjects: 10000,
            repo: JsonCacheInfoRepository(databaseName: key),
            fileService: HttpFileService(
              httpClient: LoggingClient(Client()),
            ),
            fileSystem: fsio.IOFileSystem(key),
          ),
        );
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
