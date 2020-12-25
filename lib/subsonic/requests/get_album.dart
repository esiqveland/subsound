import 'dart:convert';
import 'dart:developer';

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
    this.id,
    this.name,
    this.artistName,
    this.artistId,
    this.coverArtId,
    this.coverArtLink,
    this.year,
    this.duration,
    this.songCount,
    this.createdAt,
    this.songs,
  });

  String durationNice() {
    return formatDuration(duration);
  }
}

class SongResult {
  final String id;
  final String parent;
  final String title;
  final String artistName;
  final String artistId;
  final String albumName;
  final String albumId;
  final String coverArtId;
  final String coverArtLink;
  final int year;
  final Duration duration;
  final bool isVideo;
  final DateTime createdAt;
  final String type;
  final int bitRate;
  final int trackNumber;
  final int fileSize;
  final String contentType;
  final String suffix;

  SongResult({
    this.id,
    this.parent,
    this.title,
    this.artistName,
    this.artistId,
    this.albumName,
    this.albumId,
    this.coverArtId,
    this.coverArtLink,
    this.year,
    this.duration,
    this.isVideo,
    this.createdAt,
    this.type,
    this.bitRate,
    this.trackNumber,
    this.fileSize,
    this.suffix,
    this.contentType,
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
      return '${hours}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      var seconds = duration.inSeconds - (minutes * 60);
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }
}

const FallbackImageUrl =
    'https://lastfm.freetls.fastly.net/i/u/174s/2a96cbd8b46e442fc41c2b86b821562f.png';

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
    final coverArtId = albumDataNew['coverArt'];

    final songs = (albumDataNew['song'] as List).map((songData) {
      final songArtId = songData['coverArt'] ?? coverArtId;
      final coverArtLink = (songArtId != null && coverArtId != songArtId)
          ? GetCoverArt(songArtId).getImageUrl(ctx)
          : GetCoverArt(coverArtId).getImageUrl(ctx) ?? FallbackImageUrl;

      final duration = getDuration(songData['duration']);

      return SongResult(
        id: songData['id'],
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
        contentType: songData['contentType'] ?? '',
        suffix: songData['suffix'] ?? '',
      );
    }).toList();

    final coverArtLink = coverArtId != null
        ? GetCoverArt(coverArtId).getImageUrl(ctx)
        : FallbackImageUrl;

    log('coverArtLink=$coverArtLink');

    final duration = getDuration(albumDataNew['duration']);

    final albumResult = AlbumResult(
      id: albumDataNew['id'],
      name: albumDataNew['name'],
      artistName: albumDataNew['artist'],
      artistId: albumDataNew['artistId'],
      coverArtId: coverArtId,
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

Duration getDuration(dynamic durationParam) {
  if (durationParam is String) {
    return Duration(seconds: int.parse(durationParam));
  }
  if (durationParam is int) {
    return Duration(seconds: durationParam);
  }

  return Duration(seconds: 0);
}
