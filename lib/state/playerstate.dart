import 'dart:async';
import 'dart:developer';

import 'package:async_redux/async_redux.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:subsound/components/player.dart';
import 'package:subsound/state/appstate.dart';
import 'package:subsound/storage/cache.dart';

//final task = AudioPlayerTask();
// Must be a top-level function
void _entrypoint() => AudioServiceBackground.run(() => AudioPlayerTask());

class AudioPlayerTask extends BackgroundAudioTask {
  final _player = AudioPlayer();
  StreamSubscription<PlaybackEvent> _eventSubscription; // e.g. just_audio

  AudioPlayerTask() : super(cacheManager: ArtworkCacheManager());

  bool get _playing => AudioServiceBackground.state.playing;

  // Implement callbacks here. e.g. onStart, onStop, onPlay, onPause

  /// Called once when this audio task is first started and ready to play
  /// audio, in response to [AudioService.start]. [params] will contain any
  /// params passed into [AudioService.start] when starting this background
  /// audio task.
  @override
  Future<Function> onStart(Map<String, dynamic> params) async {
    // Broadcast that we're connecting, and what controls are available.
    AudioServiceBackground.setState(
      controls: [MediaControl.pause, MediaControl.play],
      playing: false,
      processingState: AudioProcessingState.ready,
    );
    // Broadcast that we're playing, and what controls are available.
    AudioServiceBackground.setState(
      controls: [MediaControl.pause, MediaControl.stop],
      playing: false,
      processingState: AudioProcessingState.ready,
    );
    //final session = await AudioSession.instance;
    // Handle unplugged headphones.
    // session.becomingNoisyEventStream.listen((_) {
    //   if (_playing) onPause();
    // });

    // Propagate all events from the audio player to AudioService clients.
    _eventSubscription = _player.playbackEventStream.listen((event) {
      _broadcastState();
    });

    // Special processing for state transitions.
    _player.processingStateStream.listen((state) {
      switch (state) {
        case ProcessingState.completed:
          // In this example, the service stops when reaching the end.
          //onStop();
          break;
        case ProcessingState.ready:
          // If we just came from skipping between tracks, clear the skip
          // state now that we're ready to play.
          //_skipState = null;
          break;
        default:
          break;
      }
    });

    // Listen to state changes on the player...
    _player.playerStateStream.listen((playerState) {
      // ... and forward them to all audio_service clients.
      AudioServiceBackground.setState(
        playing: playerState.playing,
        // Every state from the audio player gets mapped onto an audio_service state.
        processingState: {
          ProcessingState.idle: AudioProcessingState.none,
          ProcessingState.loading: AudioProcessingState.connecting,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[playerState.processingState],
        // Tell clients what buttons/controls should be enabled in the
        // current state.
        controls: [
          playerState.playing ? MediaControl.pause : MediaControl.play,
          MediaControl.stop,
        ],
      );
    });
  }

  /// Broadcasts the current state to all clients.
  Future<void> _broadcastState() async {
    await AudioServiceBackground.setState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: [
        MediaAction.seekTo,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      ],
      androidCompactActions: [0, 1, 3],
      processingState: _getProcessingState(),
      playing: _player.playing,
      position: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
    );
  }

  /// Maps just_audio's processing state into into audio_service's playing
  /// state. If we are in the middle of a skip, we use [_skipState] instead.
  AudioProcessingState _getProcessingState() {
    //if (_skipState != null) return _skipState;
    switch (_player.processingState) {
      case ProcessingState.idle:
        return AudioProcessingState.stopped;
      case ProcessingState.loading:
        return AudioProcessingState.connecting;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
      default:
        throw Exception("Invalid state: ${_player.processingState}");
    }
  }

  @override
  Duration get fastForwardInterval => Duration(seconds: 10);

  @override
  Duration get rewindInterval => Duration(seconds: 5);

  // Future<Function> onPrepare() {}
  // Future<Function> onPrepareFromMediaId(String mediaId) {}
  // Future<Function> onPlayFromMediaId(String mediaId) {}

  @override
  Future<Function> onPlayMediaItem(MediaItem mediaItem) async {
    final dur = await _player.setUrl(mediaItem.id);
  }

  @override
  Future<Function> onTaskRemoved() {}

  @override
  onPlay() => _player.play();

  @override
  onPause() => _player.pause();

  @override
  onSeekTo(Duration duration) => _player.seek(duration);

  @override
  onSetSpeed(double speed) => _player.setSpeed(speed);

  @override
  onStop() async {
    log('Task: onStop called');
    // Stop and dispose of the player.
    await _player.dispose();
    _eventSubscription.cancel();
    // Shut down the background task.
    await super.onStop();
  }
}

abstract class PlayerActions extends ReduxAction<AppState> {
  static final String playerId = 'e5dde786-5365-11eb-ae93-0242ac130002';

  @override
  Future<void> before() async {
    if (!AudioService.connected) {
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
    if (position > state.playerState.duration) {
      return state.copy(
        playerState:
            state.playerState.copy(position: state.playerState.duration),
      );
    }
    return state.copy(
      playerState: state.playerState.copy(position: position),
    );
  }
}

class PlayerCommandPlay extends PlayerActions {
  @override
  Future<AppState> reduce() async {
    AudioService.play();
    return state.copy(
      playerState: state.playerState.copy(current: PlayerStates.playing),
    );
  }
}

class PlayerCommandPause extends PlayerActions {
  @override
  Future<AppState> reduce() async {
    await AudioService.pause();
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
    await AudioService.seekTo(pos);
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
    if (state.playerState.duration?.inMilliseconds !=
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
  AppState reduce() => state.copy(
        playerState: state.playerState.copy(current: nextState),
      );
}

class PlayerCommandPlaySong extends PlayerActions {
  final PlayerSong song;

  PlayerCommandPlaySong(this.song);

  @override
  Future<AppState> reduce() async {
    final songUrl = song.songUrl;
    await AudioService.playMediaItem(MediaItem(
      id: songUrl,
      artist: song?.artist,
      album: song?.album,
      title: song?.songTitle,
      artUri: song?.coverArtLink,
      duration: song?.duration ?? state.playerState.duration,
    ));
    AudioService.play();
    return state.copy(
      playerState: state.playerState.copy(
        current: PlayerStates.playing,
        currentSong: song,
        duration: song?.duration ?? Duration.zero,
      ),
    );
  }
}

class StartupPlayer extends ReduxAction<AppState> {
  @override
  Future<AppState> reduce() async {
    if (!AudioService.connected) {
      await AudioService.connect();
    }

    if (AudioService.running) {
      return state.copy();
    }
    final success = await AudioService.start(
      backgroundTaskEntrypoint: _entrypoint,
      androidNotificationChannelName: 'Subsound',
      androidEnableQueue: false,

      // Enable this if you want the Android service to exit the foreground state on pause.
      //androidStopForegroundOnPause: true,
      androidNotificationColor: 0xFF2196f3,
      androidNotificationIcon: 'mipmap/ic_launcher',
      //params: DownloadAudioTask.createStartParams(downloadManager),
      androidStopForegroundOnPause: false,
    );
    log('StartupPlayer: success=$success');

    AudioService.createPositionStream(
      steps: 800,
      minPeriod: Duration(milliseconds: 500),
      maxPeriod: Duration(milliseconds: 1200),
    ).listen((event) {
      log("createPositionStream $event");
      if (event == null) {
        return;
      }
      if (state.playerState.position?.inSeconds != event.inSeconds) {
        dispatch(PlayerPositionChanged(event));
      }
    });
    AudioService.positionStream.listen((pos) {});
    AudioService.runningStream.listen((event) {
      log("runningStream: event=$event");
    });
    AudioService.playbackStateStream.listen((event) {
      log("playbackStateStream $event");
      if (event == null) {
        return;
      }
      if (event.playing && state.playerState.current != PlayerStates.playing) {
        dispatch(PlayerStateChanged(PlayerStates.playing));
      }
      if (!event.playing && state.playerState.current != PlayerStates.stopped) {
        dispatch(PlayerStateChanged(PlayerStates.stopped));
      }
    });
    AudioService.currentMediaItemStream.listen((MediaItem item) {
      log("currentMediaItemStream $item");
      if (item == null) {
        return;
      }

      if (item?.duration != null) {
        dispatch(PlayerDurationChanged(item.duration));
      }
      dispatch(PlayerStateChanged(PlayerStates.stopped));
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
