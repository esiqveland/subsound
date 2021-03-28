import 'dart:async';
import 'dart:developer';

import 'package:async_redux/async_redux.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:subsound/components/player.dart' hide PlayerState;
import 'package:subsound/state/appcommands.dart';
import 'package:subsound/state/appstate.dart';
import 'package:subsound/state/player_task.dart';
import 'package:subsound/storage/cache.dart';
import 'package:subsound/subsonic/requests/get_album.dart';
import 'package:subsound/subsonic/requests/get_artist.dart';

// Must be a top-level function
void _entrypoint() => AudioServiceBackground.run(() => AudioPlayerTask());

abstract class PlayerActions extends ReduxAction<AppState> {
  static final String playerId = 'e5dde786-5365-11eb-ae93-0242ac130002';

  @override
  Future<void> before() async {
    if (!AudioService.connected) {
      await dispatchFuture(StartupPlayer());
    }
    if (!AudioService.running) {
      await dispatchFuture(StartupPlayer());
    }
  }
}

class PlayerPositionChanged extends PlayerActions {
  final Duration position;

  PlayerPositionChanged(this.position);

  @override
  AppState reduce() {
    if (position == state.playerState.position) {
      return state;
    }
    var correctPosition = position;
    if (position > state.playerState.duration) {
      correctPosition = state.playerState.duration;
    }
    PlayerStartListenPlayerPosition.updateListeners(PositionUpdate(
      duration: state.playerState.duration,
      position: position,
    ));

    return state.copy(
      playerState: state.playerState.copy(position: correctPosition),
    );
  }
}

class PlayerCommandPlay extends PlayerActions {
  @override
  Future<AppState?> reduce() async {
    AudioService.play();
    final current = AudioService.currentMediaItem;
    if (current == null) {
      return null;
    }
    return state.copy(
      playerState: state.playerState.copy(
        current: PlayerStates.playing,
      ),
    );
  }
}

class PlayerCommandSkipNext extends PlayerActions {
  @override
  Future<AppState?> reduce() async {
    AudioService.skipToNext();
    return null;
  }
}

class PlayerCommandSkipPrev extends PlayerActions {
  @override
  Future<AppState?> reduce() async {
    AudioService.skipToPrevious();
    return null;
  }
}

class PlayerCommandPause extends PlayerActions {
  @override
  Future<AppState> reduce() async {
    AudioService.pause();
    return state.copy(
      playerState: state.playerState.copy(current: PlayerStates.paused),
    );
  }
}

class PlayerCommandSeekTo extends PlayerActions {
  final int seekToPosition;

  PlayerCommandSeekTo(this.seekToPosition);

  @override
  Future<AppState> reduce() async {
    final pos = Duration(seconds: seekToPosition);
    if (pos > state.playerState.duration) {
      log("SeekTo invalid position=$pos dur=${state.playerState.duration}");
      return state;
    }
    AudioService.seekTo(pos);
    return state.copy(
      playerState: state.playerState.copy(position: pos),
    );
  }
}

class PlayerDurationChanged extends PlayerActions {
  final Duration nextDuration;

  PlayerDurationChanged(this.nextDuration);

  @override
  AppState reduce() {
    if (state.playerState.duration.inMilliseconds !=
        nextDuration.inMilliseconds) {
      if (nextDuration < state.playerState.position) {
        return state.copy(
          playerState: state.playerState.copy(
            position: nextDuration,
            duration: nextDuration,
          ),
        );
      }
      return state.copy(
        playerState: state.playerState.copy(
          duration: nextDuration,
        ),
      );
    }
    return state;
  }
}

class PlayerStateChanged extends PlayerActions {
  final PlayerStates nextState;

  PlayerStateChanged(this.nextState);

  @override
  AppState? reduce() {
    if (state.playerState.current == nextState) {
      return null;
    }
    return state.copy(
      playerState: state.playerState.copy(current: nextState),
    );
  }
}

class PlayerCommandPlayAlbum extends PlayerActions {
  final AlbumResultSimple album;

  PlayerCommandPlayAlbum(this.album);

  @override
  Future<AppState> reduce() async {
    final albumData = await GetAlbum(album.id).run(state.loginState.toClient());
    final song = albumData.data.songs.first;

    dispatch(PlayerCommandPlaySongInAlbum(
      songId: song.id,
      album: albumData.data,
    ));

    return state;
  }
}

class PlayerCommandSetCurrentPlaying extends PlayerActions {
  final PlayerSong song;
  final Duration? duration;
  final PlayerStates? playerstate;
  final List<PlayerSong>? queue;

  PlayerCommandSetCurrentPlaying(
    this.song, {
    this.playerstate,
    this.queue,
    this.duration,
  });

  @override
  AppState reduce() {
    final next = song.copy(
      isStarred: state.dataState.isSongStarred(song.id),
    );
    return state.copy(
      playerState: state.playerState.copy(
        current: playerstate ?? state.playerState.current,
        currentSong: next,
        duration: duration ?? next.duration,
        queue: queue ?? state.playerState.queue,
      ),
    );
  }
}

class PositionUpdate {
  final Duration position;
  final Duration duration;

  PositionUpdate({required this.position, required this.duration});
}

//typedef PositionListener = Function(PositionUpdate);
abstract class PositionListener {
  void next(PositionUpdate pos);
}

class PlayerStopListenPlayerPosition extends ReduxAction<AppState> {
  final PositionListener listener;

  PlayerStopListenPlayerPosition(this.listener);

  @override
  AppState reduce() {
    PlayerStartListenPlayerPosition.removeListener(listener);
    return state.copy();
  }
}

class PlayerStartListenPlayerPosition extends ReduxAction<AppState> {
  static final List<PositionListener> _listeners = [];

  static updateListeners(PositionUpdate pos) {
    _listeners.forEach((l) => l.next(pos));
  }

  static removeListener(PositionListener l) {
    _listeners.removeWhere((element) => element == l);
  }

  static addListener(PositionListener l) {
    // if (_listeners.length > 4) {
    //   throw new Exception(
    //       'unexpected number of position listeners: ${_listeners.length} did you forget to cleanup somewhere?');
    // }

    if (!_listeners.contains(l)) {
      _listeners.add(l);
    }
  }

  final PositionListener listener;
  PlayerStartListenPlayerPosition(this.listener);

  @override
  AppState reduce() {
    PlayerStartListenPlayerPosition.addListener(listener);
    return state.copy();
  }
}

class PlayerCommandEnqueueSong extends PlayerActions {
  final PlayerSong song;

  PlayerCommandEnqueueSong(this.song);

  @override
  Future<AppState?> reduce() async {
    var mediaItem = PlayerSong.asMediaItem(song);
    AudioService.addQueueItem(mediaItem);
    return state;
  }
}

extension ToMediaItem on SongResult {
  MediaItem toMediaItem({bool playNow = false}) {
    final song = this;
    SongMetadata meta = SongMetadata(
      songId: song.id,
      songUrl: song.playUrl,
      fileExtension: song.suffix,
      fileSize: song.fileSize,
      contentType: song.contentType,
      playNow: playNow,
    );
    final playItem = MediaItem(
      id: song.id,
      artist: song.artistName,
      album: song.albumName,
      title: song.title,
      displayTitle: song.title,
      displaySubtitle: song.artistName,
      artUri: song.coverArtLink != null ? Uri.parse(song.coverArtLink) : null,
      duration: song.duration.inSeconds > 0 ? song.duration : Duration.zero,
      extras: {},
    ).setSongMetadata(meta);

    return playItem;
  }
}

class PlayerCommandContextualPlay extends PlayerActions {
  final String songId;
  final List<SongResult> playQueue;

  PlayerCommandContextualPlay({required this.songId, required this.playQueue});

  @override
  FutureOr<AppState?> reduce() {
    // TODO: implement reduce
    throw UnimplementedError();
  }
}

class PlayerCommandPlaySongInAlbum extends PlayerActions {
  final String songId;
  final AlbumResult album;

  PlayerCommandPlaySongInAlbum({required this.songId, required this.album});

  @override
  Future<AppState?> reduce() async {
    List<PlayerSong> queue = album.songs
        .map((SongResult e) => PlayerSong.from(
              e,
              state.dataState.isSongStarred(e.id),
            ))
        .toList();

    var selected = queue.singleWhere((element) => element.id == songId);

    dispatch(PlayerCommandSetCurrentPlaying(
      selected,
      playerstate: PlayerStates.playing,
      queue: queue,
    ));

    final mediaQueue = album.songs
        .map((s) => s.toMediaItem(
              playNow: s.id == songId,
            ))
        .toList();

    AudioService.updateQueue(mediaQueue);
    AudioService.playFromMediaId(songId);

    return null;
  }
}

class PlayerCommandPlaySong extends PlayerActions {
  final PlayerSong song;

  PlayerCommandPlaySong(this.song);

  @override
  Future<AppState> reduce() async {
    final next = song.copy(
      isStarred: state.dataState.isSongStarred(song.id),
    );
    final songUrl = next.songUrl;

    dispatch(PlayerCommandSetCurrentPlaying(
      next,
      playerstate: PlayerStates.stopped,
    ));

    log('PlaySong: songUrl=$songUrl');

    final mediaItem = next.toMediaItem();
    final queue = state.playerState.queue;
    final idx = queue.indexWhere((element) => element.id == song.id);
    if (idx == -1) {
      AudioService.playMediaItem(mediaItem);
    } else {
      AudioService.playFromMediaId(mediaItem.id);
    }
    AudioService.play();

    return state.copy(
      playerState: state.playerState.copy(
        current: PlayerStates.playing,
        currentSong: next,
        duration: song.duration,
      ),
    );
  }
}

extension Formatter on PlaybackState {
  String format() {
    return "PlaybackState={playing=$playing, actions=$actions, processingState=${describeEnum(processingState)}, updateTime=$updateTime,}";
  }
}

class StartupPlayer extends ReduxAction<AppState> {
  @override
  Future<AppState> reduce() async {
    if (!AudioService.connected) {
      log('StartupPlayer: not connected: ${AudioService.connected}');
      await AudioService.connect();
      log('StartupPlayer: not connected after: ${AudioService.connected}');
    }

    if (AudioService.running) {
      log('StartupPlayer: already running');
      return state.copy();
    } else {
      log('StartupPlayer: not running: will start');
    }
    final success = await AudioService.start(
      backgroundTaskEntrypoint: _entrypoint,
      //androidNotificationChannelName: 'Subsound',
      androidEnableQueue: true,

      // Enable this if you want the Android service to exit the foreground state on pause.
      androidStopForegroundOnPause: false,
      androidNotificationClickStartsActivity: true,
      androidShowNotificationBadge: false,
      androidNotificationColor: 0xFF2196f3,
      androidNotificationIcon: 'mipmap/ic_launcher',
      //params: DownloadAudioTask.createStartParams(),
    );
    log('StartupPlayer: success=$success');

    AudioService.createPositionStream(
      steps: 800,
      minPeriod: Duration(milliseconds: 500),
      maxPeriod: Duration(milliseconds: 500),
      //: Duration(milliseconds: 1000),
    ).listen((pos) {
      //log("createPositionStream $pos");
      PlayerStartListenPlayerPosition.updateListeners(PositionUpdate(
        duration: state.playerState.duration,
        position: pos,
      ));
      if (state.playerState.position.inSeconds != pos.inSeconds) {
        //dispatch(PlayerPositionChanged(pos));
      }
    });
    AudioService.positionStream.listen((pos) {});
    AudioService.runningStream.listen((event) {
      log("runningStream: event=$event");
    });

    AudioService.playbackStateStream.listen((event) {
      log("playbackStateStream event=${event.format()}");

      PlayerStates nextState =
          getNextPlayerState(event.processingState, event.playing);
      if (state.playerState.current != nextState) {
        dispatch(PlayerStateChanged(nextState));
      }
      final currentPosition = event.currentPosition;
      if (state.playerState.position != currentPosition) {
        PlayerStartListenPlayerPosition.updateListeners(PositionUpdate(
          position: currentPosition,
          duration: state.playerState.duration,
        ));
      }
    });
    AudioService.currentMediaItemStream.listen((MediaItem? item) async {
      log("currentMediaItemStream ${item?.toString()}");
      if (item == null) {
        return;
      }
      if (item.duration != null &&
          item.duration != state.playerState.duration) {
        dispatch(PlayerDurationChanged(item.duration!));
      }
      if (item.id == state.playerState.currentSong?.id) {
        return;
      }

      var id = item.id;
      var song = state.dataState.songs.getSongId(id);
      //final song = PlayerSong.fromMediaItem(item);

      if (song == null) {
        log('got unknown song from mediaItem: $id');
        await dispatchFuture(GetSongCommand(songId: id));
        final song = state.dataState.songs.getSongId(id);
        if (song == null) {
          log('got API unknown song from mediaItem: $id');
        } else {
          var ps = PlayerSong.from(song);
          dispatch(PlayerCommandSetCurrentPlaying(ps));
        }
      } else {
        var ps = PlayerSong.from(song);
        dispatch(PlayerCommandSetCurrentPlaying(ps));
      }
    });
    // PlayerActions._player.onPlayerError.listen((msg) {
    //   print('audioPlayer onError : $msg');
    //   dispatch(PlayerStateChanged(PlayerStates.stopped));
    //   dispatch(PlayerDurationChanged(Duration()));
    //   dispatch(PlayerPositionChanged(Duration()));
    //   dispatch(DisplayError('Error playing: $msg'));
    // });

    return state.copy();
  }
}

PlayerStates getNextPlayerState(
  AudioProcessingState processingState,
  bool playing,
) {
  switch (processingState) {
    case AudioProcessingState.none:
      if (playing) {
        return PlayerStates.playing;
      } else {
        return PlayerStates.stopped;
      }
    case AudioProcessingState.connecting:
      if (playing) {
        return PlayerStates.playing;
      } else {
        return PlayerStates.stopped;
      }
    case AudioProcessingState.ready:
      if (playing) {
        return PlayerStates.playing;
      } else {
        return PlayerStates.paused;
      }
    case AudioProcessingState.buffering:
      if (playing) {
        return PlayerStates.playing;
      } else {
        return PlayerStates.buffering;
      }
    case AudioProcessingState.fastForwarding:
      return PlayerStates.playing;
    case AudioProcessingState.rewinding:
      return PlayerStates.playing;
    case AudioProcessingState.skippingToPrevious:
      return PlayerStates.playing;
    case AudioProcessingState.skippingToNext:
      return PlayerStates.playing;
    case AudioProcessingState.skippingToQueueItem:
      return PlayerStates.playing;
    case AudioProcessingState.completed:
      return PlayerStates.stopped;
    case AudioProcessingState.stopped:
      return PlayerStates.stopped;
    case AudioProcessingState.error:
      return PlayerStates.stopped;
  }
}
