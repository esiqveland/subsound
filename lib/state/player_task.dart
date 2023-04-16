import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:pedantic/pedantic.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:subsound/state/appstate.dart';
import 'package:subsound/storage/cache.dart';

MyAudioHandler? _audioHandler;

MyAudioHandler get audioHandler {
  return _audioHandler!;
}

set audioHandler(MyAudioHandler h) {
  if (_audioHandler != null) {
    throw ArgumentError.value(
        'audioHandler was already set. make sure you only do this once.');
  }
  _audioHandler = h;
}

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final _player = AudioPlayer();

  final BehaviorSubject<double> volumeState = BehaviorSubject.seeded(1.0);

  MyAudioHandler() {
    // Broadcast which item is currently playing
    // _player.currentIndexStream.listen((index) {
    //   if (index != null) {
    //     mediaItem.add(queue.value![index]);
    //   }
    // });

    // Broadcast the current playback state and what controls should currently
    // be visible in the media notification
    _player.playbackEventStream.listen((event) {
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          _player.playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
        ],
        androidCompactActionIndices: [0, 1, 2],
        systemActions: {
          MediaAction.seek,
          MediaAction.playPause,
          // MediaAction.seekForward,
          // MediaAction.seekBackward,
        },
        processingState: {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: _player.playing,
        updatePosition: event.updatePosition,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      ));
    }, onError: _handleErrors, onDone: _handleDone);

    volumeState.add(_player.volume);
    _player.volumeStream.listen((event) {
      volumeState.add(event);
    });
    // skip to next song when playback completes
    _player.playbackEventStream.listen((nextState) {
      if (_player.playing &&
          nextState.processingState == ProcessingState.completed) {
        skipToNext();
      }
    }, onError: _handleErrors);
  }

  void _handleDone() {
    _handleErrors(
        "error: _handleDone called on a _player stream", StackTrace.current);
  }

  @override
  play() => _player.play();

  @override
  pause() => _player.pause();

  @override
  seek(Duration position) => _player.seek(position);

  seekTo(Duration position) => _player.seek(position);

  @override
  stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> skipToNext() async {
    await _skip(1);
  }

  @override
  Future<void> skipToPrevious() async {
    await _skip(-1);
  }

  bool get hasNext {
    final queue = this.queue.value;
    final index = playbackState.value.queueIndex!;
    return queue.length > index + 1;
  }

  Future<void> _skip(int offset) async {
    final queue = this.queue.value;
    final index = playbackState.value.queueIndex!;
    if (index >= queue.length) {
      return;
    }
    if (index + offset < 0) {
      await skipToQueueItem(0);
      await seek(Duration.zero);
      return;
    }
    if (index + offset >= queue.length) {
      await pause();
      await skipToQueueItem(0);
      return;
    }
    final isPastStart = _player.position > Duration(milliseconds: 3500);
    if (offset == -1 && isPastStart) {
      await seek(Duration.zero);
      return;
    }
    await skipToQueueItem(index + offset);
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    final q = queue.value;
    if (index < 0 || index >= q.length) return;
    await super.skipToQueueItem(index);
    var item = q[index];
    var wasPlaying = _player.playing;
    if (wasPlaying) {
      await _player.pause();
    }
    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.loading,
      queueIndex: index,
      updatePosition: Duration.zero,
    ));
    mediaItem.add(queue.value[index]);

    try {
      final source = await _toStreamSource(item);
      await _player.setAudioSource(source);
      if (wasPlaying) {
        unawaited(_player.play());
      }
    } on PlayerInterruptedException catch (_) {
      // ignore interrupts to load()
    } on Exception catch (e, st) {
      unawaited(Sentry.captureException(
        e,
        stackTrace: st,
        hint: Hint.withMap(
            {"msg": "error changing audiosource to item=${item.id}"}),
      ));
    }
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }

  @override
  Future<dynamic> customAction(String name,
      [Map<String, dynamic>? extras]) async {
    switch (name) {
      case 'setVolume':
        final vol = extras?['volume'];
        if (vol is double) {
          unawaited(_player.setVolume(vol));
        }
        break;
      case 'saveBookmark':
        // app-specific code
        break;
    }
  }

  _handleErrors(Object e, StackTrace st) async {
    try {
      // PlatformException(-1004, Could not connect to the server., null, null)
      if (e is PlatformException && e.code == '-1004') {
        Sentry.configureScope((scope) {
          scope.setExtra("handled", true);
        });
        unawaited(Sentry.captureException(
          e,
          stackTrace: st,
          hint: Hint.withMap({"handled": "true"}),
        ));
        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.error,
          errorMessage: e.code,
        ));
        return;
      }
      // PlatformException(abort, Connection aborted, null, null)
      if (e is PlatformException && e.code == 'abort') {
        Sentry.configureScope((scope) {
          scope.setExtra("handled", true);
        });
        unawaited(Sentry.captureException(
          e,
          stackTrace: st,
          hint: Hint.withMap({"handled": "true"}),
        ));
        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.error,
          errorMessage: e.code,
        ));
        return;
      }
      // PlayerException: (-1004) Could not connect to the server.
      if (e is PlayerException && e.code == -1004) {
        Sentry.configureScope((scope) {
          scope.setExtra("handled", true);
        });
        unawaited(Sentry.captureException(e,
            stackTrace: st, hint: Hint.withMap({"handled": "true"})));
        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.error,
          errorCode: e.code,
          errorMessage: e.message,
        ));
        return;
      }
      Sentry.configureScope((scope) {
        scope.setExtra("handled", false);
      });
      unawaited(Sentry.captureException(e, stackTrace: st));
    } finally {
      // try stopping the player after a crash, so it hopefully can start
      // playing again when we set a new audiosource next time.
      await _player.stop();
    }
  }
}

Future<AudioSource> _toStreamSource(MediaItem mediaItem) async {
  return _preloadedSource(mediaItem);
}

// ignore: unused_element
Future<AudioSource> _preloadedSource(MediaItem mediaItem) async {
  SongMetadata meta = mediaItem.getSongMetadata();
  var uri = Uri.parse(meta.songUrl);

  var cacheFile = await DownloadCacheManager().loadSong(CachedSong(
    songId: meta.songId,
    songUri: uri,
    fileSize: meta.fileSize,
    fileExtension: meta.fileExtension,
  ));

  var source = AudioSource.uri(cacheFile.uri);
  return source;
}

// ignore: unused_element
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

extension SongMeta on MediaItem {
  MediaItem setSongMetadata(SongMetadata s) {
    extras!["id"] = s.songId;
    extras!["songUrl"] = s.songUrl;
    extras!["extension"] = s.fileExtension;
    extras!["size"] = s.fileSize;
    extras!["type"] = s.contentType;
    extras!["playNow"] = s.playNow;
    return this;
  }

  SongMetadata getSongMetadata() {
    if (extras == null) {
      throw StateError('invalid mediaItem: $this');
    }
    return SongMetadata(
      songId: extras!["id"] as String,
      songUrl: extras!["songUrl"] as String,
      fileExtension: extras!["extension"] as String,
      fileSize: extras!["size"] as int,
      contentType: extras!["type"] as String,
      playNow: extras!["playNow"] as bool? ?? false,
    );
  }
}
