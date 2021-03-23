import 'dart:developer';

import 'package:async_redux/async_redux.dart';
import 'package:subsound/state/appstate.dart';
import 'package:subsound/state/errors.dart';
import 'package:subsound/subsonic/requests/get_album.dart';
import 'package:subsound/subsonic/requests/get_album_list.dart';
import 'package:subsound/subsonic/requests/get_album_list2.dart';
import 'package:subsound/subsonic/requests/get_artists.dart';
import 'package:subsound/subsonic/requests/get_starred2.dart';
import 'package:subsound/subsonic/requests/ping.dart';
import 'package:subsound/subsonic/requests/star.dart';
import 'package:subsound/subsonic/response.dart';

class StarIdCommand extends RunRequest {
  final ItemId id;

  StarIdCommand(this.id);

  @override
  Future<AppState?> reduce() async {
    final res = await StarItem(id: id).run(state.loginState.toClient());
    if (res.status == ResponseStatus.ok) {
      final next = state.playerState.currentSong?.id == id.getId
          ? state.playerState.copy(
              currentSong: state.playerState.currentSong?.copy(isStarred: true),
            )
          : state.playerState;

      store.dispatchFuture(RefreshStarredCommand());

      return state.copy(
        playerState: next,
      );
    } else {
      dispatch(DisplayError("something went wrong"));
    }
    return null;
  }
}

class UnstarIdCommand extends RunRequest {
  final ItemId id;

  UnstarIdCommand(this.id);

  @override
  Future<AppState?> reduce() async {
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
    }
    return null;
  }
}

class RefreshStarredCommand extends RunRequest {
  @override
  Future<AppState> reduce() async {
    final subsonicResponse =
        await GetStarred2().run(state.loginState.toClient());

    final starred = Starred.of(subsonicResponse.data);

    final dataState = state.dataState.copy(
      stars: starred,
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
  Future<AppState> reduce() async {
    final subsonicResponse =
        await GetAlbum(albumId).run(state.loginState.toClient());

    final albums = state.dataState.albums.add(subsonicResponse.data);

    return state.copy(
      dataState: state.dataState.copy(
        albums: albums,
      ),
    );
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

    final artists = state.dataState.artists.addAll(
      subsonicResponse.data.index.expand((e) => e.artist).toList(),
    );

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
