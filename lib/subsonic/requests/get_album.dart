import 'dart:convert';

import 'package:subsound/subsonic/requests/get_starred2.dart';
import 'package:subsound/subsonic/requests/stream_id.dart';
import 'package:subsound/utils/duration.dart';

import '../base_request.dart';
import '../subsonic.dart';
import 'get_cover_art.dart';

class AlbumResult {
  final String id;
  final String name;
  final String artistName;
  final String artistId;
  final String coverArtId;
  final String coverArtLink;
  final int year;
  final Duration duration;
  final int songCount;
  final List<SongResult> songs;
  final DateTime createdAt;

  AlbumResult({
    required this.id,
    required this.name,
    required this.artistName,
    required this.artistId,
    required this.coverArtId,
    required this.coverArtLink,
    required this.year,
    required this.duration,
    required this.songCount,
    required this.createdAt,
    this.songs = const [],
  });

  String durationNice() {
    return formatDuration(duration);
  }
}

class SongResult {
  final String id;
  final String playUrl;
  final String? parent;
  final String title;
  final String artistName;
  final String artistId;
  final String albumName;
  final String albumId;
  final String coverArtId;
  // TODO: convert to Uri?
  final String coverArtLink;
  final int year;
  final Duration duration;
  final bool isVideo;
  final DateTime createdAt;
  final String type;
  final int bitRate;
  final int trackNumber;
  final int fileSize;
  final bool starred;
  final DateTime? starredAt;
  final String contentType;
  final String suffix;

  SongResult({
    required this.id,
    required this.playUrl,
    this.parent,
    required this.title,
    required this.artistName,
    required this.artistId,
    required this.albumName,
    required this.albumId,
    required this.coverArtId,
    required this.coverArtLink,
    required this.year,
    required this.duration,
    this.isVideo = false,
    required this.createdAt,
    required this.type,
    required this.bitRate,
    required this.trackNumber,
    required this.fileSize,
    required this.starred,
    required this.starredAt,
    required this.suffix,
    required this.contentType,
  });

  String durationNice() {
    return formatDuration(duration);
  }

  static String formatDuration(Duration duration) {
    String twoDigits(int n) {
      if (n >= 10) return "$n";
      return "0$n";
    }

    final hours = duration.inHours;
    var minutes = duration.inMinutes;
    if (minutes > 75) {
      minutes = minutes - (hours * 60);
      var seconds = duration.inSeconds - (minutes * 60);
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      var seconds = duration.inSeconds - (minutes * 60);
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }
}

class GetSongRequest extends BaseRequest<SongResult> {
  final String id;

  GetSongRequest(this.id);

  @override
  String get sinceVersion => '1.8.0';

  @override
  Future<SubsonicResponse<SongResult>> run(SubsonicContext ctx) async {
    final response = await ctx.client
        .get(ctx.buildRequestUri('getSong', params: {'id': this.id}));

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (data['subsonic-response']['status'] != 'ok') {
      throw StateError(data);
    }

    final songData = data['subsonic-response']['song'];
    final songArtId = songData['coverArt'] ?? FallbackImageUrl;
    final coverArtLink = (songArtId != null)
        ? GetCoverArt(songArtId).getImageUrl(ctx)
        : FallbackImageUrl;

    final duration = getDuration(songData['duration']);

    final id = songData['id'];
    final playUrl = StreamItem(id).getDownloadUrl(ctx);

    final songResult = SongResult(
      id: id,
      playUrl: playUrl,
      parent: songData['parent'],
      title: songData['title'],
      artistName: songData['artist'],
      artistId: songData['artistId'],
      albumName: songData['album'],
      albumId: songData['albumId'],
      coverArtId: songArtId,
      coverArtLink: coverArtLink,
      year: songData['year'] ?? 0,
      duration: duration,
      isVideo: songData['isVideo'] ?? false,
      createdAt: DateTime.parse(songData['created']),
      type: songData['type'],
      bitRate: songData['bitRate'] ?? 0,
      trackNumber: songData['track'] ?? 0,
      fileSize: songData['size'] ?? 0,
      starred: parseStarred(songData['starred']),
      starredAt: parseDateTime(songData['starred']),
      contentType: songData['contentType'] ?? '',
      suffix: songData['suffix'] ?? '',
    );

    return SubsonicResponse(
      ResponseStatus.ok,
      data['subsonic-response']['version'],
      songResult,
    );
  }
}

class GetAlbum extends BaseRequest<AlbumResult> {
  final String id;

  GetAlbum(this.id);

  @override
  String get sinceVersion => '1.8.0';

  @override
  Future<SubsonicResponse<AlbumResult>> run(SubsonicContext ctx) async {
    final response = await ctx.client
        .get(ctx.buildRequestUri('getAlbum', params: {'id': id}));

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (data['subsonic-response']['status'] != 'ok') {
      throw StateError(data);
    }

    final albumDataNew = data['subsonic-response']['album'];
    final String? coverArtId = albumDataNew['coverArt'];

    final songs = (albumDataNew['song'] as List).map((songData) {
      final String? songArtId = songData['coverArt'] ?? coverArtId;
      final coverArtLink = (songArtId != null && coverArtId != songArtId)
          ? GetCoverArt(songArtId).getImageUrl(ctx)
          : coverArtId != null
              ? GetCoverArt(coverArtId).getImageUrl(ctx)
              : FallbackImageUrl;

      final duration = getDuration(songData['duration']);

      final id = songData['id'];
      final playUrl = StreamItem(id).getDownloadUrl(ctx);

      return SongResult(
        id: id,
        playUrl: playUrl,
        parent: songData['parent'],
        title: songData['title'],
        artistName: songData['artist'],
        artistId: songData['artistId'],
        albumName: songData['album'],
        albumId: songData['albumId'],
        coverArtId: songArtId ?? id,
        coverArtLink: coverArtLink,
        year: songData['year'] ?? 0,
        duration: duration,
        isVideo: songData['isVideo'] ?? false,
        createdAt: DateTime.parse(songData['created']),
        type: songData['type'],
        bitRate: songData['bitRate'] ?? 0,
        trackNumber: songData['track'] ?? 0,
        fileSize: songData['size'] ?? 0,
        starred: parseStarred(songData['starred']),
        starredAt: parseDateTime(songData['starred']),
        contentType: songData['contentType'] ?? '',
        suffix: songData['suffix'] ?? '',
      );
    }).toList();

    final coverArtLink = coverArtId != null
        ? GetCoverArt(coverArtId).getImageUrl(ctx)
        : FallbackImageUrl;

    // log('coverArtLink=$coverArtLink');

    final duration = getDuration(albumDataNew['duration']);

    final albumId = albumDataNew['id'];

    final albumResult = AlbumResult(
      id: albumId,
      name: albumDataNew['name'],
      artistName: albumDataNew['artist'],
      artistId: albumDataNew['artistId'],
      coverArtId: coverArtId ?? albumId,
      coverArtLink: coverArtLink,
      year: albumDataNew['year'] ?? 0,
      duration: duration,
      songCount: albumDataNew['songCount'] ?? 0,
      createdAt: DateTime.parse(albumDataNew['created']),
      songs: songs,
    );

    return SubsonicResponse(
      ResponseStatus.ok,
      data['subsonic-response']['version'],
      albumResult,
    );
  }
}
