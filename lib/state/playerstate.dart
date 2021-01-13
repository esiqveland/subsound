import 'package:async_redux/async_redux.dart';
import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:subsound/components/player.dart';

import 'appstate.dart';

abstract class PlayerActions extends ReduxAction<AppState> {
  static final String playerId = 'e5dde786-5365-11eb-ae93-0242ac130002';
  static final AudioCache _cache = AudioCache();
  static final AudioPlayer _player = AudioPlayer(playerId: playerId);
}

class PlayerPositionChanged extends PlayerActions {
  final Duration position;

  PlayerPositionChanged(this.position);

  @override
  AppState reduce() =>
      state.copy(playerState: state.playerState.copy(position: position));
}

class PlayerCommandPlay extends PlayerActions {
  @override
  Future<AppState> reduce() async {
    await PlayerActions._player.resume();
    return state.copy(
      playerState: state.playerState.copy(current: PlayerStates.playing),
    );
  }
}

class PlayerCommandPause extends PlayerActions {
  @override
  Future<AppState> reduce() async {
    await PlayerActions._player.pause();
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
    await PlayerActions._player.seek(pos);
    return state.copy(
      playerState: state.playerState.copy(position: pos),
    );
  }
}

class PlayerDurationChanged extends PlayerActions {
  final Duration duration;

  PlayerDurationChanged(this.duration);

  @override
  AppState reduce() => state.copy(
        playerState: state.playerState.copy(duration: duration),
      );
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
    var res = await PlayerActions._player.play(songUrl);
    if (res == 1) {
      return state.copy(
        playerState: state.playerState.copy(
          current: PlayerStates.playing,
          currentSong: song,
        ),
      );
    } else {
      return state.copy(
        playerState: state.playerState.copy(
          current: PlayerStates.stopped,
          currentSong: song,
        ),
      );
    }
  }
}

class PlayerCommandPlayUrl extends PlayerActions {
  final String url;

  PlayerCommandPlayUrl(this.url);

  @override
  Future<AppState> reduce() async {
    var res = await PlayerActions._player.play(url);
    if (res == 1) {
      return state.copy(
        playerState: state.playerState.copy(current: PlayerStates.playing),
      );
    } else {
      return state.copy(
        playerState: state.playerState.copy(current: PlayerStates.stopped),
      );
    }
  }
}

class StartupPlayer extends PlayerActions {
  @override
  Future<AppState> reduce() async {
    PlayerActions._player.onAudioPositionChanged.listen((event) {
      if (state.playerState.position?.inSeconds != event.inSeconds) {
        dispatch(PlayerPositionChanged(event));
      }
    });
    PlayerActions._player.onDurationChanged.listen((event) {
      if (state.playerState.duration?.inSeconds != event.inSeconds) {
        dispatch(PlayerDurationChanged(event));
      }
    });
    PlayerActions._player.onPlayerError.listen((msg) {
      print('audioPlayer onError : $msg');
      dispatch(PlayerStateChanged(PlayerStates.stopped));
      dispatch(PlayerDurationChanged(Duration()));
      dispatch(PlayerPositionChanged(Duration()));
      dispatch(DisplayError('Error playing: $msg'));
    });
    PlayerActions._player.onPlayerStateChanged.listen((event) {
      switch (event) {
        case AudioPlayerState.STOPPED:
          dispatch(PlayerStateChanged(PlayerStates.stopped));
          break;
        case AudioPlayerState.PLAYING:
          dispatch(PlayerStateChanged(PlayerStates.playing));
          break;
        case AudioPlayerState.PAUSED:
          dispatch(PlayerStateChanged(PlayerStates.paused));
          break;
        case AudioPlayerState.COMPLETED:
          dispatch(PlayerStateChanged(PlayerStates.stopped));
          break;
      }
    });
    return state.copy();
  }
}
