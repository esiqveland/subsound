import 'dart:async';
import 'dart:developer';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:subsound/state/appstate.dart';
import 'package:subsound/storage/cache.dart';

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
      final nextPos = event ?? -1;
      if (nextPos != _queuePosition) {
        _queuePosition = nextPos;
        if (nextPos >= 0 && nextPos <= _queue.length) {
          var item = _queue[nextPos];
          AudioServiceBackground.setMediaItem(item);
          _broadcastState();
        }
      }
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
      await _player.stop();
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
    final wasPlaying = _player.playing;
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

    if (wasPlaying) {
      await onPlay();
    } else {
      _broadcastState();
    }
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
    _eventSubscription?.cancel();
    _streamSubscription?.cancel();
    _stateSubscription?.cancel();
    await _player.stop();
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
