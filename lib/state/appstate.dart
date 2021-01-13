import 'dart:async';

import 'package:async_redux/async_redux.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:subsound/components/player.dart';
import 'package:subsound/state/playerstate.dart';
import 'package:subsound/subsonic/context.dart';

Store<AppState> createStore() => Store<AppState>(
      initialState: AppState.initialState(),
      actionObservers: [Log.printer(formatter: Log.verySimpleFormatter)],
      stateObservers: [StateLogger()],
      errorObserver: MyErrorObserver(),
    );

class StateLogger implements StateObserver<AppState> {
  @override
  void observe(ReduxAction<AppState> action, AppState stateIni,
      AppState stateEnd, int dispatchCount) {}
}

class MyErrorObserver<St> implements ErrorObserver<St> {
  @override
  bool observe(
    Object error,
    StackTrace stackTrace,
    ReduxAction<St> action,
    Store store,
  ) {
    print("Error thrown during $action: $error");
    return true;
  }
}

class StartupAction extends ReduxAction<AppState> {
  @override
  Future<AppState> reduce() async {
    final restored = await store.dispatchFuture(RestoreServerState());
    final startedPlayer = await store.dispatchFuture(StartupPlayer());
    await Future.delayed(Duration(seconds: 1));
    return state.copy(startUpState: StartUpState.done);
  }
}

class SaveServerState extends ReduxAction<AppState> {
  final String uri;
  final String username;
  final String password;

  SaveServerState(this.uri, this.username, this.password);

  @override
  Future<AppState> reduce() async {
    final prefs = await SharedPreferences.getInstance();
    var next = await ServerData.store(
      prefs,
      ServerData(
        uri: uri,
        username: username,
        password: password,
      ),
    );

    return state.copy(
      loginState: next,
    );
  }
}

class RestoreServerState extends ReduxAction<AppState> {
  @override
  Future<AppState> reduce() async {
    final prefs = await SharedPreferences.getInstance();
    var next = ServerData.fromPrefs(prefs);
    return state.copy(
      loginState: next,
    );
  }
}

enum StartUpState { loading, done }

class AppState {
  final StartUpState startUpState;
  final ServerData loginState;
  final UserState userState;
  final TodoState todoState;
  final PlayerState playerState;

  AppState({
    this.startUpState,
    this.loginState,
    this.userState,
    this.todoState,
    this.playerState,
  });

  AppState copy({
    StartUpState startUpState,
    ServerData loginState,
    UserState userState,
    TodoState todoState,
    PlayerState playerState,
  }) {
    return AppState(
      startUpState: startUpState ?? this.startUpState,
      loginState: loginState ?? this.loginState,
      userState: userState ?? this.userState,
      todoState: todoState ?? this.todoState,
      playerState: playerState ?? this.playerState,
    );
  }

  static AppState initialState() => AppState(
        startUpState: StartUpState.loading,
        loginState: ServerData.initialState(),
        userState: UserState.initialState(),
        todoState: TodoState.initialState(),
        playerState: PlayerState.initialState(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppState &&
          runtimeType == other.runtimeType &&
          startUpState == other.startUpState &&
          loginState == other.loginState &&
          userState == other.userState &&
          todoState == other.todoState &&
          playerState == other.playerState;

  @override
  int get hashCode =>
      startUpState.hashCode ^
      loginState.hashCode ^
      userState.hashCode ^
      todoState.hashCode ^
      playerState.hashCode;
}

class Todo {}

class TodoState {
  final List<Todo> todos;

  TodoState({this.todos});

  TodoState copy({List<Todo> todos}) {
    return TodoState(todos: todos ?? this.todos);
  }

  static TodoState initialState() => TodoState(todos: const []);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TodoState &&
            runtimeType == other.runtimeType &&
            listEquals(todos, other.todos);
  }

  @override
  int get hashCode => ListEquality().hash(todos);
}

class UserState {
  static initialState() => UserState();
}

class ServerData {
  final String uri;
  final String username;
  final String password;

  ServerData({
    @required this.uri,
    @required this.username,
    @required this.password,
  });

  SubsonicContext toClient() {
    final url = Uri.tryParse(uri);
    return SubsonicContext(
      serverId: this.uri,
      name: url.host,
      endpoint: url,
      user: username,
      pass: password,
    );
  }

  static initialState() =>
      ServerData(uri: 'https://', username: '', password: '');

  static fromPrefs(SharedPreferences prefs) {
    return new ServerData(
      uri: prefs.getString("uri") ?? "https://",
      username: prefs.getString("username") ?? "",
      password: prefs.getString("password") ?? "",
    );
  }

  static Future<ServerData> store(SharedPreferences prefs, ServerData data) {
    return Future.wait([
      prefs.setString("uri", data.uri),
      prefs.setString("username", data.username),
      prefs.setString("password", data.password),
    ]).then((value) => data);
  }

  @override
  int get hashCode => uri.hashCode ^ username.hashCode ^ password.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServerData &&
          runtimeType == other.runtimeType &&
          uri == other.uri &&
          username == other.username &&
          password == other.password;
}

class DisplayError extends ReduxAction<AppState> {
  final String errorMessage;

  DisplayError(this.errorMessage);

  @override
  Future<AppState> reduce() async {}
}
