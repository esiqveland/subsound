import 'dart:async';
import 'dart:developer';

import 'package:async_redux/async_redux.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:subsound/components/player.dart';
import 'package:subsound/state/appcommands.dart';
import 'package:subsound/state/playerstate.dart';
import 'package:subsound/subsonic/context.dart';
import 'package:subsound/subsonic/models/album.dart';
import 'package:subsound/subsonic/requests/get_album.dart';
import 'package:subsound/subsonic/requests/get_artist.dart';
import 'package:subsound/subsonic/requests/get_artists.dart';
import 'package:subsound/subsonic/requests/get_starred2.dart';
import 'package:subsound/utils/utils.dart';
import 'package:uuid/uuid.dart';

final uuid = Uuid();

Store<AppState> createStore() => Store<AppState>(
      initialState: AppState.initialState(),
      actionObservers: [Log.printer(formatter: Log.verySimpleFormatter)],
      stateObservers: [StateLogger()],
      errorObserver: MyErrorObserver(),
    );

class StateLogger implements StateObserver<AppState> {
  @override
  void observe(
    ReduxAction<AppState> action,
    AppState stateIni,
    AppState stateEnd,
    int dispatchCount,
  ) {
    // log('action=$action');
    // log('current=$stateIni');
    log('next=$stateEnd');
  }
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
    await store.dispatchFuture(RestoreServerState());
    store.dispatchFuture(RefreshAppState());
    await store.dispatchFuture(StartupPlayer());
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

class Starred {
  final Map<String, SongResult> songs;
  final Map<String, AlbumResultSimple> albums;

  Starred(this.songs, this.albums);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Starred &&
          runtimeType == other.runtimeType &&
          songs == other.songs &&
          albums == other.albums;

  @override
  int get hashCode => songs.hashCode ^ albums.hashCode;

  static Starred of(GetStarred2Result r) {
    var songs = r.songs.toMap((s) => MapEntry(s.id, s));
    var albums = r.albums.toMap((a) => MapEntry(a.id, a));
    return Starred(songs, albums);
  }

  Starred remove(String itemId) {
    var songs = Map.of(this.songs);
    songs.remove(itemId);
    var albums = Map.of(this.albums);
    albums.remove(itemId);
    return Starred(songs, albums);
  }

  Starred addSong(SongResult s) {
    var songs = Map.of(this.songs);
    songs[s.id] = s;
    return Starred(songs, albums);
  }

  Starred addAlbum(AlbumResultSimple r) {
    var albums = Map.of(this.albums);
    albums[r.id] = r;
    return Starred(songs, albums);
  }
}

class Songs {
  final Map<String, SongResult> _songs;

  Songs(this._songs);

  Songs add(SongResult s) {
    final next = Map.of(_songs);
    next[s.id] = s;
    return Songs(next);
  }
}

class Albums {
  final Map<String, Album> albums;

  Albums(this.albums);

  Albums add(AlbumResult a) {
    final next = Map.of(albums);
    next[a.id] = Album(
      id: a.id,
      artist: a.artistName,
      title: a.name,
      coverArtId: a.coverArtId,
      coverArtLink: a.coverArtLink,
      isDir: false,
    );
    return Albums(next);
  }

  Albums addAll(List<Album> data) {
    final next = Map.of(albums);
    data.forEach((a) {
      next[a.id] = a;
    });
    return Albums(next);
  }
}

class Artists {
  final Map<String, Artist> artists;

  Artists(this.artists);

  Artists add(ArtistResult a) {
    final next = Map.of(artists);
    next[a.id] = Artist(
      id: a.id,
      name: a.name,
      albumCount: a.albumCount,
      coverArtId: a.coverArtId,
      coverArtLink: a.coverArtLink,
    );
    return Artists(next);
  }

  Artists addAll(List<Artist> data) {
    final next = Map.of(artists);
    data.forEach((a) {
      next[a.id] = a;
    });

    return Artists(next);
  }
}

class DataState {
  final Starred stars;
  final Albums albums;
  final Songs songs;
  final Artists artists;

  DataState({this.stars, this.albums, this.songs, this.artists});

  DataState copy({
    Starred stars,
    Albums albums,
    Songs songs,
    Artists artists,
  }) =>
      DataState(
        stars: stars ?? this.stars,
        albums: albums ?? this.albums,
        songs: songs ?? this.songs,
        artists: artists ?? this.artists,
      );

  static DataState initialState() => DataState(
        stars: Starred({}, {}),
        albums: Albums({}),
        songs: Songs({}),
      );

  bool isStarred(SongResult s) => stars?.songs?.containsKey(s.id) ?? false;
  bool isSongStarred(String id) => stars?.songs?.containsKey(id) ?? false;
  bool isAlbumStarred(AlbumResult a) =>
      stars?.albums?.containsKey(a.id) ?? false;
  bool isAlbumIdStarred(String albumId) =>
      stars?.albums?.containsKey(albumId) ?? false;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataState &&
          runtimeType == other.runtimeType &&
          stars == other.stars;

  @override
  int get hashCode => stars.hashCode;
}

enum StartUpState { loading, done }

class AppState {
  final StartUpState startUpState;
  final ServerData loginState;
  final UserState userState;
  final TodoState todoState;
  final PlayerState playerState;
  final DataState dataState;

  AppState({
    this.startUpState,
    this.loginState,
    this.userState,
    this.todoState,
    this.playerState,
    this.dataState,
  });

  AppState copy({
    StartUpState startUpState,
    ServerData loginState,
    UserState userState,
    TodoState todoState,
    PlayerState playerState,
    DataState dataState,
  }) {
    return AppState(
      startUpState: startUpState ?? this.startUpState,
      loginState: loginState ?? this.loginState,
      userState: userState ?? this.userState,
      todoState: todoState ?? this.todoState,
      playerState: playerState ?? this.playerState,
      dataState: dataState ?? this.dataState,
    );
  }

  static AppState initialState() => AppState(
        startUpState: StartUpState.loading,
        loginState: ServerData.initialState(),
        userState: UserState.initialState(),
        todoState: TodoState.initialState(),
        playerState: PlayerState.initialState(),
        dataState: DataState.initialState(),
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
          playerState == other.playerState &&
          dataState == other.dataState;

  @override
  int get hashCode =>
      startUpState.hashCode ^
      loginState.hashCode ^
      userState.hashCode ^
      todoState.hashCode ^
      playerState.hashCode ^
      dataState.hashCode;

  @override
  String toString() {
    return 'AppState{startUpState: $startUpState, loginState: $loginState, userState: $userState, todoState: $todoState, playerState: $playerState, dataState: $dataState}';
  }
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

  bool get isValid =>
      uri.isNotEmpty && username.isNotEmpty && password.isNotEmpty;

  static initialState() => ServerData(uri: '', username: '', password: '');

  static fromPrefs(SharedPreferences prefs) {
    return new ServerData(
      uri: prefs.getString("uri") ?? "",
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
