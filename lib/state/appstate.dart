import 'dart:async';
import 'dart:developer';

import 'package:async_redux/async_redux.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:subsound/components/player.dart';
import 'package:subsound/state/appcommands.dart';
import 'package:subsound/state/database/database.dart';
import 'package:subsound/state/networkstate.dart';
import 'package:subsound/state/playerstate.dart';
import 'package:subsound/subsonic/context.dart';
import 'package:subsound/subsonic/models/album.dart';
import 'package:subsound/subsonic/requests/get_album.dart';
import 'package:subsound/subsonic/requests/get_album_list.dart';
import 'package:subsound/subsonic/requests/get_artist.dart';
import 'package:subsound/subsonic/requests/get_artists.dart';
import 'package:subsound/subsonic/requests/get_playlist.dart';
import 'package:subsound/subsonic/requests/get_starred2.dart';
import 'package:subsound/subsonic/requests/requests.dart';
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
    Object? error,
    int dispatchCount,
  ) {
    // log('action=$action');
    // log('current=$stateIni');
    log('next=$stateEnd action=$action');
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
    log(
      "Error thrown during ${action.runtimeType.toString()}: $error",
      error: error,
      stackTrace: stackTrace,
    );
    Sentry.configureScope((scope) {
      scope.setContexts("action", action.runtimeType.toString());
      scope.setTag("action", action.runtimeType.toString());
    });
    Sentry.captureException(error, stackTrace: stackTrace);
    return true;
  }
}

DB? _db;

DB get database {
  return _db!;
}

class SetDBAction extends ReduxAction<AppState> {
  final DB db;

  SetDBAction(this.db);

  @override
  AppState? reduce() {
    _db = db;
  }
}

class StartupAction extends ReduxAction<AppState> {
  final DB db;

  StartupAction(this.db);

  @override
  Future<AppState> reduce() async {
    await dispatch(SetDBAction(db));
    await store.dispatch(RestoreServerState());
    await store.dispatch(SetupCheckInternetCommand());
    await store.dispatch(CheckInternetCommand());
    store.dispatch(RefreshAppState());
    await store.dispatch(StartupPlayer());
    await Future.delayed(Duration(seconds: 1));
    // run a batch of scrobbles in the background on startup:
    dispatch(RunScrobbleBatchAction());
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
  final DateTime? _lastUpdatedAt;
  final Map<String, SongResult> songs;
  final Map<String, AlbumResultSimple> albums;

  Starred(this.songs, this.albums, this._lastUpdatedAt);

  DateTime? get lastUpdated => _lastUpdatedAt;

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
    return Starred(songs, albums, DateTime.now());
  }

  Starred remove(String itemId) {
    var songs = Map.of(this.songs);
    songs.remove(itemId);
    var albums = Map.of(this.albums);
    albums.remove(itemId);
    return Starred(songs, albums, _lastUpdatedAt);
  }

  Starred addSong(SongResult s) {
    var songs = Map.of(this.songs);
    songs[s.id] = s;
    return Starred(songs, albums, _lastUpdatedAt);
  }

  Starred addAlbum(AlbumResultSimple r) {
    var albums = Map.of(this.albums);
    albums[r.id] = r;
    return Starred(songs, albums, _lastUpdatedAt);
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

  Songs addAll(List<SongResult> songs) {
    final next = Map.of(_songs);
    for (var s in songs) {
      next[s.id] = s;
    }
    return Songs(next);
  }

  SongResult? getSongId(String id) {
    return _songs[id];
  }
}

class Albums {
  final Map<String, Album> albums;
  final Map<GetAlbumListType, List<Album>> albumLists;
  final Map<String, AlbumResult> albumResults;

  Albums(this.albums, this.albumResults, this.albumLists);

  Albums add(AlbumResult a) {
    final next2 = Map.of(albumResults);
    next2[a.id] = a;

    final next = Map.of(albums);
    next[a.id] = Album(
      id: a.id,
      artist: a.artistName,
      title: a.name,
      coverArtId: a.coverArtId,
      coverArtLink: a.coverArtLink,
      isDir: false,
    );
    return Albums(next, next2, albumLists);
  }

  Albums addAllSimple(List<AlbumResultSimple> data) {
    final next = Map.of(albums);
    for (var a in data) {
      next[a.id] = Album(
        id: a.id,
        artist: a.artistName,
        title: a.name,
        coverArtId: a.coverArtId ?? '',
        coverArtLink: a.coverArtLink ?? '',
        isDir: false,
      );
    }
    return Albums(next, albumResults, albumLists);
  }

  Albums addSet(GetAlbumListType type, List<Album> data) {
    final next = Map.of(albums);
    for (var a in data) {
      next[a.id] = a;
    }
    final l = Map.of(albumLists);
    l[type] = data;
    return Albums(next, albumResults, l);
  }

  Albums addAll(List<Album> data) {
    final next = Map.of(albums);
    for (var a in data) {
      next[a.id] = a;
    }
    return Albums(next, albumResults, albumLists);
  }

  AlbumResult? get(String albumId) {
    return albumResults[albumId];
  }
}

class Playlists {
  final Map<String, PlaylistResult> playlistList;
  final Map<String, GetPlaylistResult> playlistCache;

  Playlists(this.playlistList, this.playlistCache);

  Playlists addPlaylist(GetPlaylistResult p) {
    var m = Map.of(playlistList);
    m[p.playlist.id] = p.playlist;
    var cache = Map.of(playlistCache);
    cache[p.playlist.id] = p;
    return Playlists(m, cache);
  }

  Playlists add(PlaylistResult p) {
    var m = Map.of(playlistList);
    m[p.id] = p;
    return Playlists(m, playlistCache);
  }

  Playlists addAll(List<PlaylistResult> list) {
    var m = Map.of(playlistList);
    for (var p in list) {
      m[p.id] = p;
    }
    return Playlists(m, playlistCache);
  }
}

class Artists {
  final Map<String, Artist> artists;
  final List<ArtistIndexEntry> artistsIndex;
  final Map<String, ArtistResult> artistResults;

  Artists(this.artists, this.artistsIndex, this.artistResults);

  ArtistResult? get(String artistId) {
    return artistResults[artistId];
  }

  Artists add(ArtistResult a) {
    final next = Map.of(artists);
    next[a.id] = Artist(
      id: a.id,
      name: a.name,
      albumCount: a.albumCount,
      coverArtId: a.coverArtId,
      coverArtLink: a.coverArtLink,
    );
    final artistResults = Map.of(this.artistResults);
    artistResults[a.id] = a;
    return Artists(next, artistsIndex, artistResults);
  }

  Artists addIndex(List<ArtistIndexEntry> index) {
    return Artists(artists, index, artistResults);
  }

  Artists addAll(List<Artist> data) {
    final next = Map.of(artists);
    for (var a in data) {
      next[a.id] = a;
    }

    return Artists(next, artistsIndex, artistResults);
  }
}

class SearchResult {
  final DateTime timestamp;
  final Search3Result data;

  SearchResult(this.timestamp, this.data);
}

class Searches {
  final Map<String, SearchResult> cache;

  Searches(this.cache);

  Searches addResult(String searchTerm, SearchResult r) {
    var map = Map.of(cache);
    map[searchTerm] = r;
    return Searches(map);
  }

  SearchResult get(String query) {
    return cache[query]!;
  }
}

class DataState {
  final Starred stars;
  final Albums albums;
  final Songs songs;
  final Artists artists;
  final Playlists playlists;
  final Searches searches;

  DataState({
    required this.stars,
    required this.albums,
    required this.songs,
    required this.artists,
    required this.playlists,
    required this.searches,
  });

  DataState copy({
    Starred? stars,
    Albums? albums,
    Songs? songs,
    Artists? artists,
    Playlists? playlists,
    Searches? searches,
  }) =>
      DataState(
        stars: stars ?? this.stars,
        albums: albums ?? this.albums,
        songs: songs ?? this.songs,
        artists: artists ?? this.artists,
        playlists: playlists ?? this.playlists,
        searches: searches ?? this.searches,
      );

  static DataState initialState() => DataState(
        stars: Starred({}, {}, null),
        albums: Albums({}, {}, {}),
        songs: Songs({}),
        artists: Artists({}, [], {}),
        playlists: Playlists({}, {}),
        searches: Searches({}),
      );

  bool isStarred(SongResult s) => stars.songs.containsKey(s.id);
  bool isSongStarred(String id) => stars.songs.containsKey(id);
  bool isAlbumStarred(AlbumResult a) => stars.albums.containsKey(a.id);
  bool isAlbumIdStarred(String albumId) => stars.albums.containsKey(albumId);

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
  final PlayerState playerState;
  final DataState dataState;
  final NetworkState networkState;
  final InFlightState inFlightState;

  AppState({
    required this.startUpState,
    required this.loginState,
    required this.userState,
    required this.playerState,
    required this.dataState,
    required this.networkState,
    required this.inFlightState,
  });

  AppState copy({
    StartUpState? startUpState,
    ServerData? loginState,
    UserState? userState,
    PlayerState? playerState,
    DataState? dataState,
    NetworkState? networkState,
    InFlightState? inFlightState,
  }) {
    return AppState(
      startUpState: startUpState ?? this.startUpState,
      loginState: loginState ?? this.loginState,
      userState: userState ?? this.userState,
      playerState: playerState ?? this.playerState,
      dataState: dataState ?? this.dataState,
      networkState: networkState ?? this.networkState,
      inFlightState: inFlightState ?? this.inFlightState,
    );
  }

  static AppState initialState() => AppState(
        startUpState: StartUpState.loading,
        loginState: ServerData.initialState(),
        userState: UserState.initialState(),
        playerState: PlayerState.initialState(),
        dataState: DataState.initialState(),
        networkState: NetworkState.initialState(),
        inFlightState: InFlightState.initialState(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppState &&
          runtimeType == other.runtimeType &&
          startUpState == other.startUpState &&
          loginState == other.loginState &&
          userState == other.userState &&
          playerState == other.playerState &&
          dataState == other.dataState;

  @override
  int get hashCode =>
      startUpState.hashCode ^
      loginState.hashCode ^
      userState.hashCode ^
      playerState.hashCode ^
      dataState.hashCode;

  @override
  String toString() {
    //return 'AppState{startUpState: $startUpState, loginState: $loginState, userState: $userState, playerState: $playerState, dataState: $dataState}';
    return 'AppState{playerState: $playerState, dataState: $dataState}';
  }
}

class UserState {
  static UserState initialState() => UserState();
}

class ServerData {
  final String uri;
  final String username;
  final String password;

  const ServerData({
    required this.uri,
    required this.username,
    required this.password,
  });

  SubsonicContext toClient() {
    final url = Uri.parse(uri);
    return SubsonicContext(
      serverId: uri,
      name: url.host,
      endpoint: url,
      user: username,
      pass: password,
    );
  }

  bool get isValid =>
      uri.isNotEmpty && username.isNotEmpty && password.isNotEmpty;

  static ServerData initialState() =>
      ServerData(uri: '', username: '', password: '');

  static ServerData fromPrefs(SharedPreferences prefs) {
    return ServerData(
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

class StartRequest extends ReduxAction<AppState> {
  final String requestId;
  StartRequest(this.requestId);

  @override
  AppState? reduce() {
    var next = state.inFlightState.start(requestId);
    return state.copy(inFlightState: next);
  }
}

class FinishRequest extends ReduxAction<AppState> {
  final String requestId;
  FinishRequest(this.requestId);

  @override
  AppState? reduce() {
    var next = state.inFlightState.finish(requestId);
    return state.copy(inFlightState: next);
  }
}

class InFlightState {
  // map of request id --> operation count
  // keeps track of how many operations a request from the UI is waiting for
  final Map<String, int> requestsInFlight;

  InFlightState(this.requestsInFlight);

  InFlightState start(String requestId) {
    final m = Map.of(requestsInFlight);
    if (m.containsKey(requestId)) {
      m[requestId] = m[requestId] ?? 0 + 1;
    } else {
      m[requestId] = 1;
    }
    return InFlightState(m);
  }

  InFlightState finish(String requestId) {
    final m = Map.of(requestsInFlight);
    int count = m[requestId] ?? 0 - 1;
    if (count <= 0) {
      m.remove(requestId);
    }
    return InFlightState(m);
  }

  static InFlightState initialState() {
    return InFlightState({});
  }
}
