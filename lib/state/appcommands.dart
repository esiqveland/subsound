import 'dart:developer';

import 'package:async_redux/async_redux.dart';
import 'package:subsound/state/appstate.dart';
import 'package:subsound/state/errors.dart';
import 'package:subsound/subsonic/requests/get_album.dart';
import 'package:subsound/subsonic/requests/get_starred2.dart';
import 'package:subsound/subsonic/requests/ping.dart';
import 'package:subsound/subsonic/requests/star.dart';
import 'package:subsound/subsonic/response.dart';

class StarIdCommand extends RunRequest {
  final ItemId id;

  StarIdCommand(this.id);

  @override
  Future<AppState> reduce() async {
    final res = await StarItem(id: id).run(state.loginState.toClient());
    if (res.status == ResponseStatus.ok) {
      final next = state.playerState.currentSong?.id == id.getId
          ? state.playerState.copy(
              currentSong: state.playerState.currentSong.copy(isStarred: true),
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
  Future<AppState> reduce() async {
    final res = await UnstarItem(id: id).run(state.loginState.toClient());
    if (res.status == ResponseStatus.ok) {
      final next = state.playerState.currentSong?.id == id.getId
          ? state.playerState.copy(
              currentSong: state.playerState.currentSong.copy(isStarred: false),
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
    return state.copy(
      dataState: state.dataState.copy(
        stars: Starred.of(subsonicResponse.data),
      ),
    );
  }
}

class GetAlbumCommand extends RunRequest {
  final String albumId;

  GetAlbumCommand({this.albumId});

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

  GetSongCommand({this.songId});

  @override
  Future<AppState> reduce() async {
    final subsonicResponse =
        await Song(songId).run(state.loginState.toClient());

    final albums = state.dataState.albums.add(subsonicResponse.data);

    return state.copy(
      dataState: state.dataState.copy(
        albums: albums,
      ),
    );
  }
}

class RefreshAppState extends ReduxAction<AppState> {
  @override
  Future<AppState> reduce() async {
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
    String requestId,
  }) : this.requestId = requestId ?? uuid.v1();

  Future<AppState> reduce();
}
