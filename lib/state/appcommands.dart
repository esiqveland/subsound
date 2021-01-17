import 'package:async_redux/async_redux.dart';
import 'package:subsound/state/appstate.dart';
import 'package:subsound/state/errors.dart';
import 'package:subsound/subsonic/base_request.dart';
import 'package:subsound/subsonic/requests/get_starred2.dart';
import 'package:subsound/subsonic/requests/star.dart';
import 'package:subsound/subsonic/response.dart';

class StarIdCommand extends ReduxAction<AppState> {
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

      return state.copy(playerState: next);
    } else {
      dispatch(DisplayError("something went wrong"));
    }
  }
}

class UnstarIdCommand extends ReduxAction<AppState> {
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

      return state.copy(playerState: next);
    } else {
      dispatch(DisplayError("something went wrong"));
    }
  }
}

class GetStarred2Action extends ReduxAction<AppState> {
  @override
  Future<AppState> reduce() async {
    final subsonicResponse =
        await GetStarred2().run(state.loginState.toClient());
    return state.copy(
      dataState: state.dataState.copy(
        starred2: subsonicResponse.data,
      ),
    );
  }
}

class RunRequest<T> extends ReduxAction<AppState> {
  final String requestId;
  final BaseRequest<T> req;

  RunRequest({
    String requestId,
    this.req,
  }) : this.requestId = requestId ?? uuid.v1();

  @override
  Future<AppState> reduce() async {
    final subsonicResponse =
        await GetStarred2().run(state.loginState.toClient());
    return state.copy(
      dataState: state.dataState.copy(
        starred2: subsonicResponse.data,
      ),
    );
  }
}
