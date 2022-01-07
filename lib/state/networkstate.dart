import 'dart:async';

import 'package:async_redux/async_redux.dart';
import 'package:subsound/state/appstate.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

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

  bool get hasNetwork =>
      status == NetworkStatus.wifi || status == NetworkStatus.mobile;

  bool get isOfflineMode => appMode == NetworkAppMode.offline;

  static NetworkState initialState() => NetworkState(
        status: NetworkStatus.wifi,
        appMode: NetworkAppMode.online,
      );
}

extension Status on ConnectivityResult {
  NetworkStatus toNetworkStatus() {
    switch (this) {
      case ConnectivityResult.ethernet:
        return NetworkStatus.wifi;
      case ConnectivityResult.wifi:
        return NetworkStatus.wifi;
      case ConnectivityResult.mobile:
        return NetworkStatus.mobile;
      case ConnectivityResult.none:
        return NetworkStatus.none;
      case ConnectivityResult.bluetooth:
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
      var appMode = state.networkState.appMode;
      if (next == NetworkStatus.none) {
        appMode = NetworkAppMode.offline;
      }
      return state.copy(
        networkState: state.networkState.copy(
          status: next,
          appMode: appMode,
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
    await dispatch(SetInternetStatusCommand(status.toNetworkStatus()));
    return null;
  }
}

class SetupCheckInternetCommand extends ReduxAction<AppState> {
  static StreamSubscription<ConnectivityResult>? subscription;

  @override
  Future<AppState?> reduce() async {
    final status = await Connectivity().checkConnectivity();
    await dispatch(SetInternetStatusCommand(status.toNetworkStatus()));

    await subscription?.cancel();
    subscription = null;

    subscription = Connectivity().onConnectivityChanged.listen((result) {
      dispatch(SetInternetStatusCommand(result.toNetworkStatus()));
    });

    return null;
  }
}
