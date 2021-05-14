import 'dart:async';
import 'dart:developer';

import 'package:async_redux/async_redux.dart';
import 'package:pedantic/pedantic.dart';
import 'package:subsound/components/player.dart';
import 'package:subsound/state/appstate.dart';
import 'package:subsound/state/database/scrobbles_db.dart';
import 'package:subsound/state/errors.dart';
import 'package:subsound/state/playerstate.dart';
import 'package:subsound/subsonic/requests/get_album.dart';
import 'package:subsound/subsonic/requests/get_album_list.dart';
import 'package:subsound/subsonic/requests/get_album_list2.dart';
import 'package:subsound/subsonic/requests/get_artist.dart';
import 'package:subsound/subsonic/requests/get_artists.dart';
import 'package:subsound/subsonic/requests/get_playlist.dart';
import 'package:subsound/subsonic/requests/get_playlists.dart';
import 'package:subsound/subsonic/requests/get_starred2.dart';
import 'package:subsound/subsonic/requests/ping.dart';
import 'package:subsound/subsonic/requests/post_scrobble.dart';
import 'package:subsound/subsonic/requests/star.dart';
import 'package:subsound/subsonic/response.dart';

class StarIdCommand extends RunRequest {
  final ItemId id;

  StarIdCommand(this.id);

  @override
  Future<AppState?> reduce() async {
    final stateBefore = state.playerState.currentSong;
    if (stateBefore?.id == id.getId) {
      final starred = stateBefore?.copy(isStarred: true);
      if (starred != null) {
        dispatch(PlayerCommandSetCurrentPlaying(starred));
      }
    }
    try {
      final res = await StarItem(id: id).run(state.loginState.toClient());
      if (res.status == ResponseStatus.ok) {
        final next = state.playerState.currentSong?.id == id.getId
            ? state.playerState.copy(
                currentSong:
                    state.playerState.currentSong?.copy(isStarred: true),
              )
            : state.playerState;

        Starred stars = store.state.dataState.stars;
        SongResult? song = store.state.dataState.songs.getSongId(id.getId);
        if (song != null) {
          stars = store.state.dataState.stars.addSong(song);
        }
        unawaited(store.dispatchFuture(RefreshStarredCommand()));

        return state.copy(
          playerState: next,
          dataState: state.dataState.copy(stars: stars),
        );
      } else {
        if (stateBefore != null) {
          dispatch(PlayerCommandSetCurrentPlaying(stateBefore));
        }
        dispatch(DisplayError("something went wrong"));
      }
    } catch (e) {
      if (stateBefore != null) {
        dispatch(PlayerCommandSetCurrentPlaying(stateBefore));
      }
      rethrow;
    }
    return null;
  }
}

class UnstarIdCommand extends RunRequest {
  final ItemId id;

  UnstarIdCommand(this.id);

  @override
  Future<AppState?> reduce() async {
    PlayerSong? currentSong = state.playerState.currentSong;
    if (currentSong != null) {
      dispatch(PlayerCommandSetCurrentPlaying(
        currentSong.copy(isStarred: false),
      ));
    }
    try {
      final res = await UnstarItem(id: id).run(state.loginState.toClient());
      if (res.status == ResponseStatus.ok) {
        final next = state.playerState.currentSong?.id == id.getId
            ? state.playerState.copy(
                currentSong:
                    state.playerState.currentSong?.copy(isStarred: false),
              )
            : state.playerState;

        var itemId = id.getId;
        var stars = state.dataState.stars.remove(itemId);

        return state.copy(
          dataState: state.dataState.copy(
            stars: stars,
          ),
          playerState: next,
        );
      } else {
        dispatch(DisplayError("something went wrong"));
        if (currentSong != null) {
          dispatch(PlayerCommandSetCurrentPlaying(currentSong));
        }
      }
    } catch (e) {
      if (currentSong != null) {
        dispatch(PlayerCommandSetCurrentPlaying(currentSong));
      }
      rethrow;
    }
    return null;
  }
}

class GetPlaylistCommand extends RunRequest {
  final String playlistId;
  final bool refresh;

  GetPlaylistCommand(this.playlistId, [this.refresh = false]);

  @override
  Future<AppState?> reduce() async {
    if (!refresh &&
        state.dataState.playlists.playlistCache.containsKey(playlistId)) {
      return null;
    }
    if (state.networkState.isOfflineMode) {}

    final res =
        await GetPlaylistRequest(playlistId).run(state.loginState.toClient());
    final next = state.dataState.playlists.addPlaylist(res.data);

    return state.copy(
      dataState: state.dataState.copy(
        playlists: next,
      ),
    );
  }
}

class RefreshPlaylistsCommand extends RunRequest {
  final bool forceRefresh;

  RefreshPlaylistsCommand({this.forceRefresh = true});

  @override
  Future<AppState?> reduce() async {
    if (!forceRefresh) {}
    if (!state.networkState.hasNetwork) {}

    final resp = await GetPlaylists().run(state.loginState.toClient());

    return state.copy(
      dataState: state.dataState.copy(
        playlists: state.dataState.playlists.addAll(resp.data.playlists),
      ),
    );
  }
}

class RefreshStarredCommand extends RunRequest {
  final bool forceRefresh;

  RefreshStarredCommand({this.forceRefresh = true});

  @override
  Future<AppState> reduce() async {
    if (!forceRefresh) {}
    if (!state.networkState.hasNetwork) {}

    final subsonicResponse =
        await GetStarred2().run(state.loginState.toClient());

    final starred = Starred.of(subsonicResponse.data);

    var songs = state.dataState.songs.addAll(starred.songs.values.toList());
    final dataState = state.dataState.copy(
      stars: starred,
      songs: songs,
    );

    final song = state.playerState.currentSong?.copy(
      isStarred: dataState.isSongStarred(state.playerState.currentSong!.id),
    );

    final playerState = state.playerState.copy(
      currentSong: song,
    );

    return state.copy(
      playerState: playerState,
      dataState: dataState,
    );
  }
}

class GetAlbumCommand extends RunRequest {
  final String albumId;

  GetAlbumCommand({required this.albumId});

  @override
  Future<AppState?> reduce() async {
    AlbumResult? album = state.dataState.albums.get(albumId);
    if (album != null) {
      return null;
    }
    final subsonicResponse =
        await GetAlbum(albumId).run(state.loginState.toClient());

    album = subsonicResponse.data;

    final songs = state.dataState.songs.addAll(album.songs);
    final albums = state.dataState.albums.add(album);

    return state.copy(
      dataState: state.dataState.copy(
        albums: albums,
        songs: songs,
      ),
    );
  }
}

class GetArtistCommand extends RunRequest {
  final String artistId;

  GetArtistCommand({required this.artistId});

  @override
  Future<AppState?> reduce() async {
    ArtistResult? artistCached = state.dataState.artists.get(artistId);
    if (artistCached != null) {
      return null;
    }
    final subsonicResponse =
        await GetArtist(artistId).run(state.loginState.toClient());

    ArtistResult artist = subsonicResponse.data;

    final artists = state.dataState.artists.add(artist);
    final albums = state.dataState.albums.addAllSimple(artist.albums);

    return state.copy(
      dataState: state.dataState.copy(
        artists: artists,
        albums: albums,
      ),
    );
  }
}

class RunScrobbleBatchAction extends ReduxAction<AppState> {
  @override
  Future<AppState?> reduce() async {
    if (state.networkState.isOfflineMode) {
      log('RunScrobbleBatchAction: skip any update in offline mode');
      return null;
    }

    // run a batch of scrobbles
    var tasks = await GetScrobbleBatchDatabaseAction().run(database);
    List<Future<ScrobbleData>> futures = tasks.map((task) async {
      try {
        var res = await PostScrobbleRequest(
          task.songId,
          playedAt: task.playedAt,
        ).run(state.loginState.toClient());
        if (res.status != ResponseStatus.ok) {
          throw Exception('error with scrobble got status: ${res.status}');
        } else {
          await DeleteScrobbleDatabaseAction(task.id).run(database);
        }
        return task;
      } catch (e) {
        log('error submitting scrobble: ', error: e);
        // put the task back as an attempted task:
        var attempted = task.attempted();
        await PutScrobbleDatabaseAction(attempted);
        return attempted;
      }
    }).toList();
    await Future.wait(futures);
    return null;
  }
}

class StoreScrobbleAction extends ReduxAction<AppState> {
  final String songId;
  final DateTime playedAt;

  StoreScrobbleAction(
    this.songId, {
    DateTime? playedAt,
  }) : this.playedAt = playedAt ?? DateTime.now();

  @override
  Future<AppState?> reduce() async {
    await PutScrobbleDatabaseAction(ScrobbleData(
      id: uuid.v1().toString(),
      songId: songId,
      attempts: 0,
      playedAt: playedAt,
      state: ScrobbleState.added,
    )).run(database);

    // run a batch of scrobbles
    unawaited(dispatchFuture(RunScrobbleBatchAction()));

    return null;
  }
}

class GetSongCommand extends RunRequest {
  final String songId;

  GetSongCommand({required this.songId});

  @override
  Future<AppState> reduce() async {
    final subsonicResponse =
        await GetSongRequest(songId).run(state.loginState.toClient());

    final song = subsonicResponse.data;
    final songs = state.dataState.songs.add(song);

    return state.copy(
      dataState: state.dataState.copy(
        songs: songs,
      ),
    );
  }
}

class GetAlbumsCommand extends RunRequest {
  final int pageSize;
  final int offset;
  final GetAlbumListType type;

  GetAlbumsCommand({
    this.type = GetAlbumListType.alphabeticalByName,
    this.pageSize = 50,
    this.offset = 0,
  });

  @override
  Future<AppState> reduce() async {
    final subsonicResponse = await GetAlbumList2(
      type: this.type,
      size: this.pageSize,
      offset: this.offset,
    ).run(state.loginState.toClient());

    final albums = state.dataState.albums.addAll(subsonicResponse.data);

    return state.copy(
      dataState: state.dataState.copy(
        albums: albums,
      ),
    );
  }
}

class GetArtistsCommand extends RunRequest {
  GetArtistsCommand();

  @override
  Future<AppState> reduce() async {
    final subsonicResponse =
        await GetArtistsRequest().run(state.loginState.toClient());

    final artists = state.dataState.artists
        .addAll(
          subsonicResponse.data.index.expand((e) => e.artist).toList(),
        )
        .addIndex(subsonicResponse.data.index);

    return state.copy(
      dataState: state.dataState.copy(
        artists: artists,
      ),
    );
  }
}

class RefreshAppState extends ReduxAction<AppState> {
  @override
  Future<AppState?> reduce() async {
    if (!state.loginState.isValid) {
      return null;
    }

    final ctx = state.loginState.toClient();
    try {
      final ping = await Ping().run(ctx);
      if (ping.status != ResponseStatus.ok) {
        log('ping failed: ${ping.data}');
        return null;
      }

      await store.dispatchFuture(RefreshStarredCommand());
    } catch (err) {
      log('RefreshAppState error: ', error: err);
    }
    return null;
  }
}

abstract class RunRequest extends ReduxAction<AppState> {
  final String requestId;

  RunRequest({
    String? requestId,
  }) : this.requestId = requestId ?? uuid.v1();

  Future<AppState?> reduce();
}
