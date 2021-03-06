import 'dart:async';
import 'dart:developer';

import 'package:async_redux/async_redux.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'package:pedantic/pedantic.dart';
import 'package:subsound/state/appstate.dart';
import 'package:subsound/state/playerstate.dart';
import 'package:subsound/storage/cache.dart';

import './player_task.dart';

class AudioWidgetModel extends Vm {
  final Function onConnect;
  final Function onDisconnect;

  AudioWidgetModel({
    required this.onConnect,
    required this.onDisconnect,
  }) : super(equals: []);
}

class AudioWidgetModelFactory extends VmFactory<AppState, MyAudioWidget> {
  AudioWidgetModelFactory(MyAudioWidget myAudioWidget) : super(myAudioWidget);

  @override
  AudioWidgetModel fromStore() {
    return AudioWidgetModel(
      onConnect: () => dispatch(StartupPlayer()),
      onDisconnect: () => dispatch(CleanupPlayer()),
    );
  }
}

class MyAudioWidget extends StatelessWidget {
  final Widget child;

  const MyAudioWidget({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, AudioWidgetModel>(
      vm: () => AudioWidgetModelFactory(this),
      builder: (context, vm) => _MyAudioWidgetStateful(child: child, model: vm),
    );
  }
}

class _MyAudioWidgetStateful extends StatefulWidget {
  final Widget child;
  final AudioWidgetModel model;

  _MyAudioWidgetStateful({
    required this.child,
    required this.model,
  });

  @override
  State<_MyAudioWidgetStateful> createState() => _AudioServiceWidgetState();
}

class _AudioServiceWidgetState extends State<_MyAudioWidgetStateful>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
    widget.model.onConnect();
  }

  @override
  void dispose() {
    widget.model.onDisconnect();
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        widget.model.onConnect();
        break;
      case AppLifecycleState.paused:
        widget.model.onDisconnect();
        break;
      default:
        break;
    }
  }

  @override
  Future<bool> didPopRoute() async {
    widget.model.onDisconnect();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

Future<AudioSource> _toStreamSource(MediaItem mediaItem) async {
  return _toAudioSource(mediaItem, mediaItem.getSongMetadata());
}

Future<AudioSource> _toAudioSource(
  MediaItem mediaItem,
  SongMetadata meta,
) async {
  var uri = Uri.parse(meta.songUrl);

  var cacheFile = await DownloadCacheManager().getCachedSongFile(CachedSong(
    songId: meta.songId,
    songUri: uri,
    fileSize: meta.fileSize,
    fileExtension: meta.fileExtension,
  ));
  var source = LockCachingAudioSource(
    uri,
    cacheFile: cacheFile,
    //tag: ,
    headers: {
      "X-Request-ID": uuid.v1().toString(),
      "Host": uri.host,
    },
  );
  return source;
}

class PlayQueue {
  final AudioPlayer player;
  final List<MediaItem> _queue = [];
  ConcatenatingAudioSource audioSource;
  int _currentIndex = -1;
  AudioProcessingState? _skipState;

  PlayQueue({required this.player, required this.audioSource});

  bool hasItem(String mediaId) =>
      _queue.indexWhere((element) => element.id == mediaId) != -1;
  bool get hasNext => _currentIndex + 1 < _queue.length;
  bool get hasPrev => _currentIndex > 0;
  AudioProcessingState? get skipState => _skipState;

  MediaItem? get currentMediaItem =>
      _currentIndex == -1 ? null : _queue[_currentIndex];

  Future<void> playItemInQueue(String mediaId) async {
    final idx = _queue.indexWhere((element) => element.id == mediaId);
    if (idx == -1) {
      log('Tried to play mediaId=$mediaId that was not present in the queue=${_queue.length}');
      return;
    } else {
      _currentIndex = idx;
      var item = _queue[_currentIndex];

      // ignore: deprecated_member_use
      unawaited(AudioServiceBackground.setMediaItem(item));
      await player.seek(Duration.zero, index: _currentIndex);
      unawaited(player.play());
    }
  }

  Future<void> addItem(MediaItem mediaItem) async {
    _queue.add(mediaItem);
    final src = await _toStreamSource(mediaItem);
    await audioSource.add(src);
    // ignore: deprecated_member_use
    await AudioServiceBackground.setQueue(_queue);
  }

  Future<void> playItem(MediaItem mediaItem) async {
    final idx = _queue.indexWhere((element) => element.id == mediaItem.id);
    if (idx == -1) {
      unawaited(player.pause());
      _queue.clear();
      _queue.add(mediaItem);
      final length = audioSource.length;

      await audioSource.add(await _toStreamSource(mediaItem));

      if (length > 0) {
        await audioSource.removeRange(0, length);
      }

      // ignore: deprecated_member_use
      unawaited(AudioServiceBackground.setQueue(_queue));
      _currentIndex = 0;
    } else {
      _currentIndex = idx;
    }
    // ignore: deprecated_member_use
    unawaited(AudioServiceBackground.setMediaItem(mediaItem));
    await player.seek(Duration.zero, index: _currentIndex);
    unawaited(player.play());
  }

  Future<void> replaceWith(List<MediaItem> replaceQueue) async {
    await player.pause();
    _queue.clear();
    _queue.addAll(replaceQueue);

    final items =
        replaceQueue.map((e) => MediaItemMeta(e, e.getSongMetadata())).toList();
    final playNowIdx = items.indexWhere((element) => element.meta.playNow);
    _currentIndex = playNowIdx;

    List<AudioSource> sources =
        await Future.wait(items.map((MediaItemMeta mediaItem) async {
      final src = await _toAudioSource(mediaItem.mediaItem, mediaItem.meta);
      return src;
    }));
    final nextSource = ConcatenatingAudioSource(children: sources);
    audioSource = nextSource;
    if (playNowIdx != -1) {
      await player.setAudioSource(nextSource, initialIndex: playNowIdx);
      await player.seek(Duration.zero, index: playNowIdx);
      // ignore: deprecated_member_use
      unawaited(AudioServiceBackground.setMediaItem(_queue[playNowIdx]));
      unawaited(player.play());
    } else {
      await player.setAudioSource(nextSource);
    }
    // ignore: deprecated_member_use
    unawaited(AudioServiceBackground.setQueue(_queue));
  }

  Future<void> setCurrentIndex(int nextIdx) async {
    if (nextIdx == _currentIndex) {
      return;
    }
    if (nextIdx >= _queue.length) {
      return;
    }
    _currentIndex = nextIdx;
    if (nextIdx == -1) {
      await player.pause();
    } else {
      final item = _queue[nextIdx];
      // ignore: deprecated_member_use
      await AudioServiceBackground.setMediaItem(item);
    }
  }

  Future<void> skipRelative(int offset) async {
    final nextPos = _currentIndex + offset;
    if (nextPos < 0 && _queue.isNotEmpty && offset < 0) {
      await player.seek(Duration.zero);
      return;
    }
    final wasPlaying = player.playing;
    final playbackPosition = player.position;
    if (offset == -1 && playbackPosition.inMilliseconds > 4000) {
      await player.seek(Duration.zero);
      return;
    }
    if (nextPos < 0) {
      return;
    }
    if (nextPos >= _queue.length) {
      await player.pause();
      await player.seek(Duration.zero);
      return;
    }

    // if (_playing == null) _playing = true;
    // _skipState = offset > 0
    //     ? AudioProcessingState.skippingToNext
    //     : AudioProcessingState.skippingToPrevious;

    _currentIndex = nextPos;
    // ignore: deprecated_member_use
    await AudioServiceBackground.setMediaItem(_queue[nextPos]);

    await player.seek(Duration.zero, index: nextPos);
    _skipState = null;

    if (wasPlaying) {
      unawaited(player.play());
    }
  }
}

// ignore: deprecated_member_use
class AudioPlayerTask extends BackgroundAudioTask {
  // e.g. just_audio
  final _player = AudioPlayer();
  late final PlayQueue _playQueue;

  AudioPlayerTask() : super();

  StreamSubscription<PlaybackEvent>? _eventSubscription;
  StreamSubscription<ProcessingState>? _streamSubscription;
  StreamSubscription<PlayerState>? _stateSubscription;
  StreamSubscription<int?>? _idxSubscription;

  // used to track state when we are in a skip transition
  AudioProcessingState? get _skipState => _playQueue._skipState;
  set _skipState(AudioProcessingState? next) => _playQueue._skipState = next;

  /// Called once when this audio task is first started and ready to play
  /// audio, in response to [AudioService.start]. [params] will contain any
  /// params passed into [AudioService.start] when starting this background
  /// audio task.
  Future<void> onStart(Map<String, dynamic>? params) async {
    final _audioSource = ConcatenatingAudioSource(children: []);

    _playQueue = PlayQueue(
      player: _player,
      audioSource: _audioSource,
    );

    // Broadcast that we're connecting, and what controls are available.
    unawaited(_broadcastState());

    // Handle unplugged headphones.
    // session.becomingNoisyEventStream.listen((_) {
    //   if (_playing) onPause();
    // });

    // Propagate all events from the audio player to AudioService clients.
    _eventSubscription = _player.playbackEventStream.listen((event) {
      if (event.currentIndex != null) {
        // there is a bug in playbackEventStream that sends the previous
        // index when seeking to a new index...
        //
        // _playQueue.setCurrentIndex(event.currentIndex!).then((value) {
        //   _broadcastState();
        // });
      }
    });
    _idxSubscription = _player.currentIndexStream.listen((event) {
      final nextPos = event ?? -1;
      _playQueue.setCurrentIndex(nextPos).whenComplete(() {
        _broadcastState();
      });
    });

    // Special processing for state transitions.
    _streamSubscription = _player.processingStateStream.listen((state) {
      switch (state) {
        case ProcessingState.completed:
          // In this example, the service stops when reaching the end.
          onPause();
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

    final item = _playQueue.currentMediaItem;
    if (item != null) {
      // ignore: deprecated_member_use
      unawaited(AudioServiceBackground.setMediaItem(item));
    }

    unawaited(_player.setAudioSource(_audioSource, preload: false));

    unawaited(_broadcastState());
  }

  List<MediaAction> getActions() {
    return [
      if (_player.playing) MediaAction.pause else MediaAction.play,
      MediaAction.seek,
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
    // ignore: deprecated_member_use
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
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
      default:
        return AudioProcessingState.idle;
    }
  }

  @override
  Duration get fastForwardInterval => Duration(seconds: 10);

  @override
  Duration get rewindInterval => Duration(seconds: 5);

  // Future<Function> onPrepare() {}
  // Future<Function> onPrepareFromMediaId(String mediaId) {}

  @override
  Future<void> onPlayFromMediaId(String mediaId) async {
    await _playQueue.playItemInQueue(mediaId);
    await _broadcastState();
    unawaited(onPlay());
  }

  @override
  Future<void> onAddQueueItemAt(MediaItem mediaItem, int index) async {
    await _playQueue.addItem(mediaItem);
    unawaited(_broadcastState());
  }

  @override
  Future<void> onUpdateQueue(List<MediaItem> replaceQueue) async {
    log('onUpdateQueue q=${replaceQueue.map((e) => e.title).join(", ")}');
    await _playQueue.replaceWith(replaceQueue);
    await _broadcastState();
  }

  @override
  Future<void> onAddQueueItem(MediaItem mediaItem) async {
    log('onAddQueueItem item=$mediaItem');
    await _playQueue.addItem(mediaItem);
    unawaited(_broadcastState());
  }

  @override
  Future<void> onPlayMediaItem(MediaItem mediaItem) async {
    log('onPlayMediaItem item=$mediaItem');
    if (_playQueue.hasItem(mediaItem.id)) {
      await _playQueue.playItemInQueue(mediaItem.id);
    } else {
      await _playQueue.playItem(mediaItem);
    }
    await _broadcastState();
    unawaited(onPlay());
  }

  @override
  Future<void> onSkipToNext() async {
    if (_playQueue.hasNext) {
      await _skipRelative(1);
    } else {
      await onPause();
      await _broadcastState();
    }
  }

  @override
  Future<void> onSkipToPrevious() async {
    if (_playQueue.hasPrev) {
      await _skipRelative(-1);
    } else {
      await onSeekTo(Duration.zero);
      await _broadcastState();
    }
  }

  @override
  Future<void> onSkipToQueueItem(String mediaId) async {
    await _playQueue.playItemInQueue(mediaId);
    await _broadcastState();
  }

  Future<void> _skipRelative(int offset) async {
    await _playQueue.skipRelative(offset);
    await _broadcastState();
  }

  @override
  Future<void> onTaskRemoved() async {
    await onStop();
    await super.onTaskRemoved();
  }

  @override
  Future<void> onPlay() async {
    unawaited(_player.play());
    await _broadcastState();
  }

  @override
  Future<void> onPause() async {
    await _player.pause();
    await _broadcastState();
  }

  @override
  Future<void> onSeekTo(Duration duration) => _player.seek(duration);

  @override
  Future<void> onSetSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> onClick(MediaButton? button) async {
    switch (button) {
      case MediaButton.media:
        unawaited(playPause());
        break;
      case MediaButton.next:
        unawaited(onSkipToNext());
        break;
      case MediaButton.previous:
        unawaited(onSkipToPrevious());
        break;
      case null:
        break;
    }
  }

  Future<void> playPause() async {
    if (_player.playing) {
      unawaited(onPause());
    } else {
      unawaited(onPlay());
    }
  }

  @override
  Future<void> onStop() async {
    log('Task: onStop called');
    // Stop and dispose of the player.
    unawaited(_eventSubscription?.cancel());
    unawaited(_streamSubscription?.cancel());
    unawaited(_stateSubscription?.cancel());
    unawaited(_idxSubscription?.cancel());
    await _player.stop();
    //await _player.dispose();
    // Shut down the background task.
    await super.onStop();
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
