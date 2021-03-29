import 'package:async_redux/async_redux.dart';
import 'package:connectivity/connectivity.dart';
import 'package:subsound/state/appstate.dart';

enum NetworkStatus { wifi, mobile, none }
enum NetworkAppMode { online, offline }

class NetworkState {
  final NetworkStatus status;
  final NetworkAppMode appMode;

  NetworkState({
    required this.status,
    required this.appMode,
  });

  NetworkState copy({
    NetworkStatus? status,
    NetworkAppMode? appMode,
  }) =>
      NetworkState(
        status: status ?? this.status,
        appMode: appMode ?? this.appMode,
      );

  static NetworkState initialState() => NetworkState(
        status: NetworkStatus.wifi,
        appMode: NetworkAppMode.online,
      );
}

extension Status on ConnectivityResult {
  NetworkStatus toNetworkStatus() {
    switch (this) {
      case ConnectivityResult.wifi:
        return NetworkStatus.wifi;
      case ConnectivityResult.mobile:
        return NetworkStatus.mobile;
      case ConnectivityResult.none:
        return NetworkStatus.none;
    }
  }
}

class SetInternetStatusCommand extends ReduxAction<AppState> {
  final NetworkStatus next;
  SetInternetStatusCommand(this.next);
  @override
  AppState? reduce() {
    if (state.networkState.status == next) {
      return null;
    } else {
      return state.copy(
        networkState: state.networkState.copy(
          status: next,
        ),
      );
    }
  }
}

// Connectivity changes are no longer communicated to Android apps
// in the background starting with Android O.
//
// You should always check for connectivity status when your app is resumed.
// The broadcast is only useful when your application is in the foreground.
class CheckInternetCommand extends ReduxAction<AppState> {
  @override
  Future<AppState?> reduce() async {
    final status = await Connectivity().checkConnectivity();
    dispatch(SetInternetStatusCommand(status.toNetworkStatus()));
    return null;
  }
}

class SetupCheckInternetCommand extends ReduxAction<AppState> {
  @override
  Future<AppState?> reduce() async {
    final status = await Connectivity().checkConnectivity();
    dispatch(SetInternetStatusCommand(status.toNetworkStatus()));

    // TODO: find a way to cancel stream...
    var stream = Connectivity().onConnectivityChanged.listen((result) {
      dispatch(SetInternetStatusCommand(result.toNetworkStatus()));
    });
    //stream.cancel();

    return null;
  }
}
