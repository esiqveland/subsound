import 'dart:async';
import 'dart:developer';

import 'package:async_redux/async_redux.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:subsound/components/player.dart' hide PlayerState;
import 'package:subsound/state/appcommands.dart';
import 'package:subsound/state/appstate.dart';
import 'package:subsound/storage/cache.dart';
import 'package:subsound/subsonic/requests/get_album.dart';
import 'package:subsound/subsonic/requests/get_artist.dart';

//final task = AudioPlayerTask();
// Must be a top-level function
void _entrypoint() => AudioServiceBackground.run(() => AudioPlayerTask());

class PlayQueue {
  final List<MediaItem> _queue = [];
  final int _currentIndex = -1;
  final ConcatenatingAudioSource audioSource;

  PlayQueue({required this.audioSource});

  bool get hasNext => _currentIndex + 1 < _queue.length;
  bool get hasPrev => _currentIndex > 0;
  MediaItem? get currentMediaItem =>
      _currentIndex == -1 ? null : _queue[_currentIndex];
}

class AudioPlayerTask extends BackgroundAudioTask {
  // e.g. just_audio
  final _player = AudioPlayer();
  final _audioSource = ConcatenatingAudioSource(children: []);

  StreamSubscription<PlaybackEvent>? _eventSubscription;
  StreamSubscription<ProcessingState>? _streamSubscription;
  StreamSubscription<PlayerState>? _stateSubscription;

  // used to track state when we are in a skip transition
  AudioProcessingState? _skipState;

  final List<MediaItem> _queue = [];
  int _queuePosition = -1;

  bool get hasNext => _queuePosition + 1 < _queue.length;
  bool get hasPrev => _queuePosition > 0;
  MediaItem? get currentMediaItem =>
      _queuePosition == -1 ? null : _queue[_queuePosition];

  AudioPlayerTask() : super(cacheManager: ArtworkCacheManager());

  bool get _playing => _player.playing;

  /// Called once when this audio task is first started and ready to play
  /// audio, in response to [AudioService.start]. [params] will contain any
  /// params passed into [AudioService.start] when starting this background
  /// audio task.
  @override
  Future<void> onStart(Map<String, dynamic>? params) async {
    // Broadcast that we're connecting, and what controls are available.
    _broadcastState();

    // Handle unplugged headphones.
    // session.becomingNoisyEventStream.listen((_) {
    //   if (_playing) onPause();
    // });

    // Propagate all events from the audio player to AudioService clients.
    _eventSubscription = _player.playbackEventStream.listen((event) {
      if (event.currentIndex != null) {
        _queuePosition = event.currentIndex!;
      }
      _broadcastState();
    });
    _player.currentIndexStream.listen((event) {
      _queuePosition = event ?? -1;
    });

    // Special processing for state transitions.
    _streamSubscription = _player.processingStateStream.listen((state) {
      switch (state) {
        case ProcessingState.completed:
          // In this example, the service stops when reaching the end.
          //onStop();
          break;
        case ProcessingState.ready:
          // If we just came from skipping between tracks, clear the skip
          // state now that we're ready to play.
          _skipState = null;
          break;
        default:
          break;
      }
    });

    // Listen to state changes on the player...
    _stateSubscription = _player.playerStateStream.listen((playerState) {
      // ... and forward them to all audio_service clients.
      _broadcastState();
    });

    final item = currentMediaItem;
    if (item != null) {
      AudioServiceBackground.setMediaItem(item);
    }

    _player.setAudioSource(_audioSource, preload: false);

    _broadcastState();
  }

  List<MediaAction> getActions() {
    return [
      if (_player.playing) MediaAction.pause else MediaAction.play,
      MediaAction.seekTo,
      // MediaAction.seekForward,
      // MediaAction.seekBackward,
    ];
  }

  List<MediaControl> getControls() {
    return [
      MediaControl.skipToPrevious,
      if (_player.playing) MediaControl.pause else MediaControl.play,
      MediaControl.skipToNext,
    ];
  }

  /// Broadcasts the current state to all clients.
  Future<void> _broadcastState() async {
    await AudioServiceBackground.setState(
      controls: getControls(),
      systemActions: getActions(),
      androidCompactActions: [1],
      processingState: _getProcessingState(),
      playing: _player.playing,
      position: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      repeatMode: _getLoopMode(),
      shuffleMode: _player.shuffleModeEnabled
          ? AudioServiceShuffleMode.all
          : AudioServiceShuffleMode.none,
    );
  }

  /// Maps just_audio's processing state into into audio_service's playing
  /// state. If we are in the middle of a skip, we use [_skipState] instead.
  AudioProcessingState _getProcessingState() {
    if (_skipState != null) return _skipState!;

    switch (_player.processingState) {
      case ProcessingState.idle:
        return AudioProcessingState.none;
      case ProcessingState.loading:
        return AudioProcessingState.connecting;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
      default:
        return AudioProcessingState.none;
    }
  }

  @override
  Duration get fastForwardInterval => Duration(seconds: 10);

  @override
  Duration get rewindInterval => Duration(seconds: 5);

  // Future<Function> onPrepare() {}
  // Future<Function> onPrepareFromMediaId(String mediaId) {}

  Future<void> onPlayFromMediaId(String mediaId) async {
    final idx = _queue.indexWhere((element) => element.id == mediaId);
    if (idx == -1) {
      log('Tried to play mediaId=$mediaId that was not present in the queue=${_queue.length}');
      return;
    } else {
      var mediaItem = _queue[idx];
      _queuePosition = idx;
      await AudioServiceBackground.setMediaItem(mediaItem);
      _broadcastState();
      await _player.seek(Duration.zero, index: idx);
      _broadcastState();
      onPlay();
    }
  }

  @override
  Future<void> onUpdateQueue(List<MediaItem> replaceQueue) async {
    _queuePosition = -1;
    if (replaceQueue.length > 0) {
      _queuePosition = 0;
    }
    _queue.clear();
    _queue.addAll(replaceQueue);
    await _audioSource.clear();

    List<AudioSource> sources =
        await Future.wait(replaceQueue.map((MediaItem mediaItem) async {
      final src = await _toAudioSource(mediaItem);
      return src;
    }));

    await _audioSource.addAll(sources);
  }

  @override
  Future<void> onAddQueueItem(MediaItem mediaItem) async {
    _queue.add(mediaItem);
    var source = await _toAudioSource(mediaItem);
    await _audioSource.add(source);
  }

  @override
  Future<void> onPlayMediaItem(MediaItem mediaItem) async {
    final foundIdx = _queue.indexWhere((element) => element.id == mediaItem.id);
    if (foundIdx != -1) {
      await onSkipToQueueItem(mediaItem.id);
      return;
    } else {
      await AudioServiceBackground.setMediaItem(mediaItem);
      final insertIndex = 0;
      var source = await _toAudioSource(mediaItem);
      _queue.clear();
      _queue.add(mediaItem);
      _queuePosition = insertIndex;
      await _audioSource.clear();
      await _audioSource.add(source);
      await _player.seek(Duration.zero, index: insertIndex);
      await _broadcastState();
      if (insertIndex == 0 && !_playing) {
        onPlay();
      }
    }
  }

  @override
  Future<void> onSkipToNext() => _skipRelative(1);

  @override
  Future<void> onSkipToPrevious() => _skipRelative(-1);

  @override
  Future<void> onSkipToQueueItem(String mediaId) async {
    var currentIdx = _queuePosition;
    final idx = _queue.indexWhere((item) => item.id == mediaId);
    if (idx != -1) {
      _skipRelative(idx - currentIdx);
    }
  }

  Future<void> _skipRelative(int offset) async {
    final nextPos = _queuePosition + offset;
    if (nextPos < 0 && _queue.length > 0 && offset < 0) {
      await onSeekTo(Duration.zero);
      return;
    }
    final playbackPosition = _player.position;
    if (offset == -1 && playbackPosition.inMilliseconds > 4000) {
      await onSeekTo(Duration.zero);
      return;
    }
    // TODO: wrap around to the start?
    if (nextPos < 0) {
      return;
    }
    if (nextPos >= _queue.length) {
      await onPause();
      await onSeekTo(Duration.zero);
      return;
    }

    // if (_playing == null) _playing = true;
    _skipState = offset > 0
        ? AudioProcessingState.skippingToNext
        : AudioProcessingState.skippingToPrevious;
    _broadcastState();
    _queuePosition = nextPos;
    AudioServiceBackground.setMediaItem(_queue[nextPos]);
    await _player.seek(Duration.zero, index: nextPos);
    _broadcastState();

    _skipState = null;

    // if (_playing) {
    await onPlay();
    // } else {
    //   _setState(processingState: AudioProcessingState.ready);
    // }
  }

  @override
  Future<void> onTaskRemoved() async {
    await onStop();
    await super.onTaskRemoved();
  }

  @override
  Future<void> onPlay() async {
    await _player.play();
    _broadcastState();
  }

  @override
  Future<void> onPause() async {
    await _player.pause();
    _broadcastState();
  }

  @override
  Future<void> onSeekTo(Duration duration) => _player.seek(duration);

  @override
  Future<void> onSetSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> onClick(MediaButton button) async {
    switch (button) {
      case MediaButton.media:
        playPause();
        break;
      case MediaButton.next:
        _skipRelative(1);
        break;
      case MediaButton.previous:
        _skipRelative(-1);
        break;
    }
  }

  Future<void> playPause() async {
    if (_player.playing) {
      onPause();
    } else {
      onPlay();
    }
  }

  @override
  Future<void> onStop() async {
    log('Task: onStop called');
    // Stop and dispose of the player.
    await _player.stop();
    _eventSubscription?.cancel();
    _streamSubscription?.cancel();
    _stateSubscription?.cancel();
    await _player.dispose();
    // Shut down the background task.
    await super.onStop();
  }

  Future<AudioSource> _toAudioSource(MediaItem mediaItem) async {
    SongMetadata meta = mediaItem.getSongMetadata()!;
    var uri = Uri.parse(meta.songUrl);
    var cacheFile = await DownloadCacheManager().getCachedSongFile(meta);

    var source = LockCachingAudioSource(
      uri,
      cacheFile: cacheFile,
      headers: {
        "X-Request-ID": uuid.v1().toString(),
        "Host": uri.host,
      },
    );
    return source;
  }

  AudioServiceRepeatMode _getLoopMode() {
    switch (_player.loopMode) {
      case LoopMode.off:
        return AudioServiceRepeatMode.none;
      case LoopMode.one:
        return AudioServiceRepeatMode.one;
      case LoopMode.all:
        return AudioServiceRepeatMode.all;
    }
  }
}

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

extension SongMeta on MediaItem {
  MediaItem setSongMetadata(SongMetadata s) {
    extras!["id"] = s.songId;
    extras!["songUrl"] = s.songUrl;
    extras!["extension"] = s.fileExtension;
    extras!["size"] = s.fileSize;
    extras!["type"] = s.contentType;
    return this;
  }

  SongMetadata? getSongMetadata() {
    if (extras == null) {
      return null;
    }
    return SongMetadata(
      songId: extras!["id"],
      songUrl: extras!["songUrl"],
      fileExtension: extras!["extension"],
      fileSize: extras!["size"],
      contentType: extras!["type"],
    );
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
    await AudioService.skipToNext();
    return null;
  }
}

class PlayerCommandSkipPrev extends PlayerActions {
  @override
  Future<AppState?> reduce() async {
    await AudioService.skipToPrevious();
    return null;
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

    dispatch(PlayerCommandPlaySong(PlayerSong.from(song)));

    return state;
  }
}

class PlayerCommandSetCurrentPlaying extends PlayerActions {
  final PlayerSong song;
  final PlayerStates playerstate;

  PlayerCommandSetCurrentPlaying(
    this.song, {
    this.playerstate = PlayerStates.stopped,
  });

  @override
  AppState reduce() {
    final next = song.copy(
      isStarred: state.dataState.isSongStarred(song.id),
    );
    return state.copy(
      playerState: state.playerState.copy(
        current: playerstate,
        currentSong: next,
        duration: next.duration,
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
    await AudioService.addQueueItem(mediaItem);
    return state;
  }
}

extension ToMediaItem on SongResult {
  MediaItem toMediaItem() {
    final song = this;
    SongMetadata meta = SongMetadata(
      songId: song.id,
      songUrl: song.playUrl,
      fileExtension: song.suffix,
      fileSize: song.fileSize,
      contentType: song.contentType,
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
    SongResult selected =
        album.songs.singleWhere((element) => element.id == songId);
    PlayerSong s =
        PlayerSong.from(selected, state.dataState.isSongStarred(songId));

    dispatch(PlayerCommandSetCurrentPlaying(
      s,
      playerstate: PlayerStates.paused,
    ));

    final queue = album.songs.map((s) => s.toMediaItem()).toList();

    await AudioService.pause();
    await AudioService.updateQueue(queue);
    await AudioService.playFromMediaId(songId);

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

    var mediaItem = PlayerSong.asMediaItem(next);
    await AudioService.playMediaItem(mediaItem);
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
      androidEnableQueue: false,

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

      switch (event.processingState) {
        case AudioProcessingState.none:
          dispatch(PlayerStateChanged(PlayerStates.stopped));
          break;
        case AudioProcessingState.connecting:
          if (event.playing) {
            dispatch(PlayerStateChanged(PlayerStates.playing));
          } else {
            dispatch(PlayerStateChanged(PlayerStates.stopped));
          }
          break;
        case AudioProcessingState.ready:
          if (event.playing) {
            dispatch(PlayerStateChanged(PlayerStates.playing));
          } else {
            dispatch(PlayerStateChanged(PlayerStates.paused));
          }
          break;
        case AudioProcessingState.buffering:
          if (event.playing) {
            dispatch(PlayerStateChanged(PlayerStates.playing));
          } else {
            dispatch(PlayerStateChanged(PlayerStates.buffering));
          }
          break;
        case AudioProcessingState.fastForwarding:
          break;
        case AudioProcessingState.rewinding:
          break;
        case AudioProcessingState.skippingToPrevious:
          break;
        case AudioProcessingState.skippingToNext:
          break;
        case AudioProcessingState.skippingToQueueItem:
          break;
        case AudioProcessingState.completed:
          dispatch(PlayerStateChanged(PlayerStates.stopped));
          break;
        case AudioProcessingState.stopped:
          dispatch(PlayerStateChanged(PlayerStates.stopped));
          break;
        case AudioProcessingState.error:
          dispatch(PlayerStateChanged(PlayerStates.stopped));
          break;
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

      if (item.duration != null) {
        dispatch(PlayerDurationChanged(item.duration!));
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
