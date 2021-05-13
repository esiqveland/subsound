import 'dart:async';
import 'dart:developer';

import 'package:async_redux/async_redux.dart';
import 'package:audio_service/audio_service.dart';
import 'package:pedantic/pedantic.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:subsound/components/player.dart' hide PlayerState;
import 'package:subsound/state/appcommands.dart';
import 'package:subsound/state/appstate.dart';
import 'package:subsound/state/errors.dart';
import 'package:subsound/state/player_task.dart';
import 'package:subsound/state/queue.dart';
import 'package:subsound/storage/cache.dart';
import 'package:subsound/subsonic/requests/get_album.dart';
import 'package:subsound/subsonic/requests/get_artist.dart';

import 'player_task.dart';

// Must be a top-level function
// void _entrypoint() => AudioServiceBackground.run(() => AudioPlayerTask());

abstract class PlayerActions extends ReduxAction<AppState> {
  static final String playerId = 'e5dde786-5365-11eb-ae93-0242ac130002';

  @override
  Future<void> before() async {
    // if (!AudioService.connected) {
    //   await dispatchFuture(StartupPlayer());
    // }
    // if (!AudioService.running) {
    //   await dispatchFuture(StartupPlayer());
    // }
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
    unawaited(audioHandler.play());

    final current = audioHandler.mediaItem.valueWrapper?.value;
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
    await audioHandler.skipToNext();
    return null;
  }
}

class PlayerCommandSkipPrev extends PlayerActions {
  @override
  Future<AppState?> reduce() async {
    await audioHandler.skipToPrevious();
    return null;
  }
}

class PlayerCommandPause extends PlayerActions {
  @override
  Future<AppState?> reduce() async {
    // optimistic UI update
    dispatch(PlayerStateChanged(PlayerStates.paused));
    try {
      await audioHandler.pause();
    } on Exception {
      dispatch(PlayerStateChanged(PlayerStates.stopped));
      rethrow;
    }
    return null;
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
    audioHandler.seekTo(pos);
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

class PlayerSetQueueIndex extends PlayerActions {
  final int? queuePosition;

  PlayerSetQueueIndex(this.queuePosition);

  @override
  AppState? reduce() {
    final q = state.playerState.queue;
    if (q.position == queuePosition) {
      return null;
    }
    return state.copy(
      playerState: state.playerState.copy(
        queue: q.copy(
          nextPosition: queuePosition,
        ),
      ),
    );
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
  final Queue? queue;

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
  final SongResult song;

  PlayerCommandEnqueueSong(this.song);

  @override
  Future<AppState?> reduce() async {
    final PlayerSong s = PlayerSong.from(song);
    final q = state.playerState.queue.add(QueueItem(s, QueuePriority.user));

    final items = q.toList.map((e) => e.song.toMediaItem()).toList();
    await audioHandler.updateQueue(items);

    return state.copy(
      playerState: state.playerState.copy(
        queue: q,
      ),
    );
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
      id: song.playUrl,
      artist: song.artistName,
      album: song.albumName,
      title: song.title,
      displayTitle: song.title,
      displaySubtitle: song.artistName,
      artUri:
          song.coverArtLink.isNotEmpty ? Uri.parse(song.coverArtLink) : null,
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
  Future<AppState?> reduce() async {
    List<QueueItem> queue = playQueue
        .map((SongResult e) => PlayerSong.from(
              e,
              state.dataState.isSongStarred(e.id),
            ))
        .map((e) => QueueItem(e, QueuePriority.low))
        .toList();

    var selectedIdx = queue.indexWhere((element) => element.song.id == songId);
    var selected = queue[selectedIdx].song;

    dispatch(PlayerCommandSetCurrentPlaying(
      selected,
      playerstate: PlayerStates.playing,
      queue: Queue(queue, selectedIdx),
    ));

    final mediaQueue = playQueue.map((s) => s.toMediaItem()).toList();

    await audioHandler.updateQueue(mediaQueue);
    await audioHandler.skipToQueueItem(selectedIdx);
    unawaited(audioHandler.play());

    return null;
  }
}

class PlayerCommandPlaySongInAlbum extends PlayerActions {
  final String songId;
  final AlbumResult album;

  PlayerCommandPlaySongInAlbum({required this.songId, required this.album});

  @override
  Future<AppState?> reduce() async {
    List<QueueItem> queue = album.songs
        .map((SongResult e) => PlayerSong.from(
              e,
              e.starred || state.dataState.isSongStarred(e.id),
            ))
        .map((song) => QueueItem(song, QueuePriority.low))
        .toList();

    var selectedIdx = queue.indexWhere((element) => element.song.id == songId);
    var selected = queue[selectedIdx].song;

    dispatch(PlayerCommandSetCurrentPlaying(
      selected,
      playerstate: PlayerStates.playing,
      queue: Queue(queue, selectedIdx),
    ));

    final mediaQueue = album.songs
        .map((s) => s.toMediaItem(
              playNow: s.id == songId,
            ))
        .toList();

    await audioHandler.updateQueue(mediaQueue);
    await audioHandler.skipToQueueItem(selectedIdx);
    unawaited(audioHandler.play());

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
    final idx =
        queue.toList.indexWhere((element) => element.song.id == song.id);
    if (idx == -1) {
      await audioHandler.playMediaItem(mediaItem);
    } else {
      await audioHandler.playFromMediaId(mediaItem.id);
    }
    unawaited(audioHandler.play());

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
    return this.toString();
    //return "PlaybackState={playing=$playing, processingState=${describeEnum(processingState)}, queueIndex=$queueIndex, errorMessage=$errorMessage, updateTime=$updateTime,}";
  }
}

class CleanupPlayer extends ReduxAction<AppState> {
  @override
  Future<AppState> reduce() async {
    await StartupPlayer.disconnect();
    return state.copy();
  }
}

// How much of the song to play before we scrobble.
// 0.7 == 70% of the song.
const ScrobbleThreshold = 0.5;
const ScrobbleMinimumDuration = Duration(seconds: 30);
const ScrobbleAlwaysPlaytime = Duration(minutes: 4);

class PlayerScrobbleState {
  final bool playing;
  final MediaItem? item;
  final Duration? position;
  final DateTime startedAt;

  PlayerScrobbleState({
    required this.playing,
    this.item,
    this.position,
    required this.startedAt,
  });

  PlayerScrobbleState copyWith({
    bool? playing,
    MediaItem? item,
    Duration? position,
    DateTime? startedAt,
  }) =>
      PlayerScrobbleState(
        playing: playing ?? this.playing,
        item: item ?? this.item,
        position: position ?? this.position,
        startedAt: startedAt ?? this.startedAt,
      );
}

final BehaviorSubject<PlayerScrobbleState> playerScrobbles =
    BehaviorSubject.seeded(PlayerScrobbleState(
  playing: false,
  startedAt: DateTime.now(),
));

class StartupPlayer extends ReduxAction<AppState> {
  static StreamSubscription<Duration>? positionStream;
  static StreamSubscription<bool>? runningStream;
  static StreamSubscription<PlaybackState>? playbackStream;
  static StreamSubscription<MediaItem?>? currentMediaStream;

  Future<void> connectListeners() async {
    await disconnect();
    log('connectListeners() called');
    positionStream = AudioService.createPositionStream(
      steps: 800,
      minPeriod: Duration(milliseconds: 500),
      maxPeriod: Duration(milliseconds: 500),
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

    playbackStream = audioHandler.playbackState.listen((event) {
      log("playbackStateStream event=${event.format()}");
      if (event.processingState == AudioProcessingState.error) {
        dispatch(DisplayError(
            "${event.errorCode ?? -1}: ${event.errorMessage ?? ''}"));
      }
      if (state.playerState.queue.position != event.queueIndex) {
        dispatch(PlayerSetQueueIndex(event.queueIndex));
      }
      bool wasPlaying = state.playerState.isPlaying;
      if (wasPlaying != event.playing) {
        playerScrobbles.add(playerScrobbles.value!.copyWith(
          playing: event.playing,
          startedAt: DateTime.now(),
          position: event.position,
        ));
      }
      PlayerStates nextState =
          getNextPlayerState(event.processingState, event.playing);
      if (state.playerState.current != nextState) {
        dispatch(PlayerStateChanged(nextState));
      }
      final currentPosition = event.position;
      if (state.playerState.position != currentPosition) {
        PlayerStartListenPlayerPosition.updateListeners(PositionUpdate(
          position: currentPosition,
          duration: state.playerState.duration,
        ));
      }
    }, onError: (err, stackTrace) {
      log("playbackStateStream error=$err", error: err);
      Sentry.configureScope((scope) {
        scope.setContexts("action", "playbackStateStream");
        scope.setTag("action", "playbackStateStream");
      });
      Sentry.captureException(err, stackTrace: stackTrace);
      dispatch(DisplayError("$err"));
    });
    currentMediaStream = audioHandler.mediaItem.listen((MediaItem? item) async {
      log("currentMediaItemStream ${item?.toString()}");
      if (item == null) {
        return;
      }
      if (item.duration != null &&
          item.duration != state.playerState.duration) {
        dispatch(PlayerDurationChanged(item.duration!));
      }
      var songMetadata = item.getSongMetadata();
      var id = songMetadata.songId;

      var prev = playerScrobbles.value!;
      playerScrobbles.add(prev.copyWith(
        playing: audioHandler.playbackState.value!.playing,
        position: Duration.zero,
        item: item,
        startedAt: DateTime.now(),
      ));

      if (prev.playing) {
        var duration = prev.item?.duration;
        if (duration != null) {
          var continuousPlayTime = DateTime.now().difference(prev.startedAt);
          var playedPortion =
              continuousPlayTime.inMilliseconds / duration.inMilliseconds;
          log('playedPortion=${playedPortion} prev.startedAt=${prev.startedAt}');

          // https://www.last.fm/api/scrobbling#when-is-a-scrobble-a-scrobble
          // Send scrobble when:
          // 1. the song has been played for more than 4 minutes OR
          // 2. the song is longer than 30 seconds AND the song played for at least 50% of it's duration
          //
          // TODO(scrobble): handle scrobbling when the last track of a playqueue finishes
          // ie. player goes to the completed state and stops playing.
          if (continuousPlayTime > ScrobbleAlwaysPlaytime ||
              duration > ScrobbleMinimumDuration &&
                  playedPortion >= ScrobbleThreshold) {
            unawaited(dispatchFuture(StoreScrobbleAction(
              id,
              playedAt: prev.startedAt,
            )));
          }
        } else {
          log('prev.item?.duration${prev.item?.duration} prev.item=${prev.item}');
        }
      } else {
        log('prev.playing=${prev.playing}');
      }

      if (id == state.playerState.currentSong?.id) {
        return;
      }

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
  }

  static Future<void> disconnect() async {
    await positionStream?.cancel();
    positionStream = null;
    await runningStream?.cancel();
    runningStream = null;
    await playbackStream?.cancel();
    playbackStream = null;
    await currentMediaStream?.cancel();
    currentMediaStream = null;
  }

  @override
  Future<AppState> reduce() async {
    // if (!AudioService.connected) {
    //   log('StartupPlayer: not connected: ${AudioService.connected}');
    //   await AudioService.connect();
    //   connectListeners();
    //   log('StartupPlayer: not connected after: ${AudioService.connected}');
    // }

    // if (AudioService.running) {
    //   log('StartupPlayer: already running');
    //   connectListeners();
    //   return state.copy();
    // } else {
    //   log('StartupPlayer: not running: will start');
    // }
    await disconnect();

    // final success = await AudioService.start(
    //   backgroundTaskEntrypoint: _entrypoint,
    //   //androidNotificationChannelName: 'Subsound',
    //   androidEnableQueue: true,
    //
    //   // Enable this if you want the Android service to exit the foreground state on pause.
    //   androidStopForegroundOnPause: false,
    //   androidNotificationClickStartsActivity: true,
    //   androidShowNotificationBadge: false,
    //   androidNotificationColor: 0xFF2196f3,
    //   androidNotificationIcon: 'mipmap/ic_launcher',
    //   //params: DownloadAudioTask.createStartParams(),
    // );
    //log('StartupPlayer: success=$success');
    await connectListeners();
    return state.copy();
  }
}

PlayerStates getNextPlayerState(
  AudioProcessingState processingState,
  bool playing,
) {
  switch (processingState) {
    case AudioProcessingState.ready:
      if (playing) {
        return PlayerStates.playing;
      } else {
        return PlayerStates.paused;
      }
    case AudioProcessingState.buffering:
      if (playing) {
        return PlayerStates.buffering;
      } else {
        return PlayerStates.buffering;
      }
    case AudioProcessingState.completed:
      return PlayerStates.stopped;
    case AudioProcessingState.error:
      return PlayerStates.stopped;
    case AudioProcessingState.idle:
      return PlayerStates.stopped;
    case AudioProcessingState.loading:
      return PlayerStates.buffering;
  }
}
