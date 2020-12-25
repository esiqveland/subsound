import 'package:meta/meta.dart';

class Song {
  final String id;
  final String serverId;
  final String parent;
  final bool isDir;
  final String title;
  final String album;
  final String artist;
  final int track;
  final int year;
  final String coverArt;
  final int size;
  final String contentType;
  final String suffix;
  final Duration duration;
  final int bitRate;
  final String path;
  final bool isVideo;
  final int playCount;
  final DateTime created;
  final String albumId;
  final String artistId;
  final String type;

  Song({
    @required this.id,
    @required this.serverId,
    this.parent,
    this.isDir,
    @required this.title,
    this.album,
    this.artist,
    this.track,
    this.year,
    this.coverArt,
    this.size,
    this.contentType,
    this.suffix,
    this.duration,
    this.bitRate,
    this.path,
    this.isVideo,
    this.playCount,
    this.created,
    this.albumId,
    this.artistId,
    this.type,
  });

  factory Song.parse(Map<String, dynamic> data, {@required String serverId}) {
    return Song(
      id: data['id'].toString(),
      serverId: serverId,
      parent: data['parent'].toString(),
      isDir: data['isDir'] == true || data['isDir'].toString().toLowerCase() == 'true',
      title: data['title'],
      album: data['album'],
      artist: data['artist'],
      track: data['track'],
      year: data['year'],
      coverArt: data['coverArt'],
      size: data['size'],
      contentType: data['contentType'],
      suffix: data['suffix'],
      duration: Duration(seconds: data['duration']),
      bitRate: data['bitRate'],
      path: data['path'],
      isVideo: data['isVideo'],
      playCount: data['playCount'],
      created: DateTime.parse(data['created']),
      albumId: data['albumId'].toString(),
      artistId: data['artistId'].toString(),
      type: data['type'],
    );
  }

  @override
  String toString() {
    return 'Song{id: $id, title: $title}';
  }
}
