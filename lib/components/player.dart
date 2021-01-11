import 'package:async_redux/async_redux.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:subsound/screens/login/myscaffold.dart';
import 'package:subsound/state/appstate.dart';
import 'package:subsound/subsonic/requests/get_album.dart';
import 'package:subsound/utils/duration.dart';

class PlayerSong {
  final String id;
  final String songTitle;
  final String album;
  final String artist;
  final String artistId;
  final String albumId;
  final String coverArtId;
  final String coverArtLink;
  final String songUrl;
  final bool isStarred;

  PlayerSong({
    this.id,
    this.songTitle,
    this.artist,
    this.album,
    this.artistId,
    this.albumId,
    this.coverArtId,
    this.coverArtLink,
    this.songUrl,
    this.isStarred = false,
  });

  static from(SongResult s) => PlayerSong(
        id: s.id,
        songTitle: s.title,
        album: s.albumName,
        artist: s.artistName,
        artistId: s.artistId,
        albumId: s.albumId,
        coverArtId: s.coverArtId,
        coverArtLink: s.coverArtLink,
        songUrl: s.playUrl,
        isStarred: false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerSong &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          songTitle == other.songTitle &&
          artist == other.artist &&
          album == other.album &&
          artistId == other.artistId &&
          albumId == other.albumId &&
          coverArtId == other.coverArtId &&
          coverArtLink == other.coverArtLink &&
          songUrl == other.songUrl &&
          isStarred == other.isStarred;

  @override
  int get hashCode =>
      id.hashCode ^
      songTitle.hashCode ^
      artist.hashCode ^
      album.hashCode ^
      artistId.hashCode ^
      albumId.hashCode ^
      coverArtId.hashCode ^
      coverArtLink.hashCode ^
      songUrl.hashCode ^
      isStarred.hashCode;
}

enum PlayerStates { stopped, playing, paused, buffering }

class PlayerState {
  final PlayerStates current;
  final PlayerSong currentSong;
  final List<PlayerSong> queue;
  final Duration duration;
  final Duration position;

  PlayerState({
    this.current,
    this.currentSong,
    this.queue,
    this.duration,
    this.position,
  });

  get isPlaying => current == PlayerStates.playing;

  get isPaused =>
      current == PlayerStates.paused || current == PlayerStates.buffering;

  get isStopped => current == PlayerStates.stopped;

  void pause() {}

  PlayerState copy({
    PlayerStates current,
    PlayerSong currentSong,
    List<PlayerSong> queue,
    Duration duration,
    Duration position,
  }) =>
      PlayerState(
        current: current ?? this.current,
        currentSong: currentSong ?? this.currentSong,
        queue: queue ?? this.queue,
        duration: duration ?? this.duration,
        position: position ?? this.position,
      );

  static initialState() => PlayerState(
        current: PlayerStates.stopped,
        currentSong: null,
        queue: [],
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerState &&
          runtimeType == other.runtimeType &&
          current == other.current &&
          currentSong == other.currentSong &&
          queue == other.queue &&
          duration == other.duration &&
          position == other.position;

  @override
  int get hashCode =>
      current.hashCode ^
      currentSong.hashCode ^
      queue.hashCode ^
      duration.hashCode ^
      position.hashCode;
}

class _PlayerViewModelFactory extends VmFactory<AppState, PlayerView> {
  _PlayerViewModelFactory(widget) : super(widget);

  @override
  PlayerViewModel fromStore() {
    return PlayerViewModel(
      songTitle: state.playerState.currentSong?.songTitle,
      artistTitle: state.playerState.currentSong?.artist,
      albumTitle: state.playerState.currentSong?.album,
      duration: state.playerState.duration,
      position: state.playerState.position,
      playerState: state.playerState.current,
      onPlay: () => dispatch(PlayerCommandPlay()),
      onPause: () => dispatch(PlayerCommandPause()),
    );
  }
}

class PlayerViewModel extends Vm {
  final String songTitle;
  final String artistTitle;
  final String albumTitle;
  final Duration duration;
  final Duration position;
  final PlayerStates playerState;
  final Function onPlay;
  final Function onPause;

  PlayerViewModel({
    @required this.songTitle,
    @required this.artistTitle,
    @required this.albumTitle,
    @required this.duration,
    @required this.position,
    @required this.playerState,
    @required this.onPlay,
    @required this.onPause,
  }) : super(equals: [
          artistTitle,
          songTitle,
          albumTitle,
          duration,
          position,
          playerState,
        ]);
}

class PlayerView extends StatelessWidget {
  final PlayerState playerState;

  const PlayerView({
    Key key,
    this.playerState,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black26,
      child: StoreConnector<AppState, PlayerState>(
        //vm: _PlayerViewModelFactory(this),
        converter: (st) => st.state.playerState,
        builder: (context, vm) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints.tightForFinite(width: 400),
            //color: Colors.tealAccent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SongTitle(playerState: vm),
                  ],
                ),
                SizedBox(height: 10.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ArtistTitle(playerState: vm),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PlayerSlider(playerState: vm, size: 300.0),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () {},
                      child: Icon(Icons.skip_previous, size: 42.0),
                    ),
                    PlayButton(state: vm, size: 72.0),
                    InkWell(
                      onTap: () {},
                      child: Icon(Icons.skip_next, size: 42.0),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SongTitle extends StatelessWidget {
  final PlayerState playerState;

  const SongTitle({Key key, this.playerState}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      playerState.currentSong?.songTitle ?? 'Fdasfdsafdsafdsafdsz',
      style: TextStyle(fontSize: 18.0),
    );
  }
}

class ArtistTitle extends StatelessWidget {
  final PlayerState playerState;

  const ArtistTitle({Key key, this.playerState}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      playerState.currentSong?.artist ?? "Bklbjxcjblkvcxjblkvcxjkl",
      style: theme.textTheme.subtitle1
          .copyWith(fontSize: 12.0, color: Colors.white70),
    );
  }
}

class PlayerScreen extends StatelessWidget {
  static final String routeName = "/player";

  const PlayerScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      body: (context) => PlayerView(),
    );
  }
}

class PlayerSlider extends StatelessWidget {
  final PlayerState playerState;
  final double size;

  PlayerSlider({Key key, this.playerState, this.size}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final total = _getMax(playerState);
    final position = _getPosition(playerState);

    return ProgressBar(
      onChanged: (nextValue) {},
      position: position,
      total: total,
      size: size,
    );
  }

  static Duration _getMax(PlayerState playerState) {
    if (playerState == null || playerState.currentSong == null) {
      return Duration(seconds: 279);
    }
    return playerState.duration;
  }

  static Duration _getPosition(PlayerState playerState) {
    if (playerState == null || playerState.currentSong == null) {
      return Duration(seconds: 100);
    }
    return playerState.position;
  }

  static double _getProgressValue(PlayerState playerState) {
    if (playerState == null || playerState.currentSong == null) {
      return 0.9;
    }
    var duration = playerState.duration.inMilliseconds.toDouble();
    if (duration == 0.0) {
      duration = 1.0;
    }
    return playerState.position.inMilliseconds.toDouble() / duration;
  }
}

class ProgressBar extends StatelessWidget {
  final Duration total;
  final Duration position;
  final double size;
  final Function(int) onChanged;

  ProgressBar({
    Key key,
    @required this.onChanged,
    this.total,
    this.position,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var positionText = formatDuration(position);
    var remaining =
        Duration(microseconds: total.inMicroseconds - position.inMicroseconds);
    var remainingText = "-" + formatDuration(remaining);

    final divisions = total.inSeconds < 1 ? 1 : total.inSeconds;

    return Container(
      width: size,
      child: Column(
        children: [
          Slider(
            activeColor: Colors.tealAccent,
            label: positionText,
            onChanged: (double newValue) {
              final nextValue = newValue.round();
              this.onChanged(nextValue);
            },
            min: 0.0,
            max: total.inSeconds.toDouble(),
            value: position.inSeconds.toDouble(),
            divisions: divisions,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(positionText, style: TextStyle(fontSize: 16.0)),
              Text(remainingText, style: TextStyle(fontSize: 16.0)),
            ],
          )
        ],
      ),
    );
  }
}

class PlayButton extends StatelessWidget {
  final PlayerState state;
  final double size;

  const PlayButton({
    Key key,
    this.state,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: _getIcon(),
    );
  }

  _getIcon() {
    if (state == null || state.current == null) {
      return Icon(Icons.play_arrow, size: size);
    }
    if (state.current == PlayerStates.playing) {
      return Icon(Icons.pause, size: size);
    }
    if (state.current == PlayerStates.paused) {
      return Icon(Icons.play_arrow, size: size);
    }
    if (state.current == PlayerStates.stopped) {
      return Icon(Icons.play_arrow, size: size);
    }
    if (state.current == PlayerStates.buffering) {
      return Icon(Icons.pause, size: size);
    }
    return Icon(Icons.play_arrow, size: size);
  }
}

class _MiniPlayerModelFactory extends VmFactory<AppState, MiniPlayer> {
  _MiniPlayerModelFactory(widget) : super(widget);

  @override
  MiniPlayerModel fromStore() {
    return MiniPlayerModel(
      songTitle: state.playerState.currentSong?.songTitle,
      artistTitle: state.playerState.currentSong?.artist,
      albumTitle: state.playerState.currentSong?.album,
      duration: state.playerState.duration,
      position: state.playerState.position,
      playerState: state.playerState.current,
      onPlay: () => dispatch(PlayerCommandPlay()),
      onPause: () => dispatch(PlayerCommandPause()),
    );
  }
}

class MiniPlayerModel extends Vm {
  final String songTitle;
  final String artistTitle;
  final String albumTitle;
  final Duration duration;
  final Duration position;
  final PlayerStates playerState;
  final Function onPlay;
  final Function onPause;

  MiniPlayerModel({
    @required this.songTitle,
    @required this.artistTitle,
    @required this.albumTitle,
    @required this.duration,
    @required this.position,
    @required this.playerState,
    @required this.onPlay,
    @required this.onPause,
  }) : super(equals: [
          artistTitle,
          songTitle,
          albumTitle,
          duration,
          position,
          playerState,
        ]);
}

class MiniPlayer extends StatelessWidget {
  final double size;

  const MiniPlayer({Key key, this.size}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50.0,
      child: StoreConnector<AppState, MiniPlayerModel>(
        vm: _MiniPlayerModelFactory(this),
        builder: (context, state) => Container(
          child: ListTile(
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => PlayerView(),
                enableDrag: true,
                isDismissible: false,
              );
            },
            visualDensity: VisualDensity(horizontal: 0, vertical: 0),
            dense: true,
            isThreeLine: true,
            leading: Icon(
              Icons.album,
              color: Colors.white,
            ),
            title: Text(
              state.songTitle ?? 'Nothing playing',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              state.artistTitle ?? '',
              style: TextStyle(fontWeight: FontWeight.normal, fontSize: 12.0),
              overflow: TextOverflow.ellipsis,
            ),
            trailing: PlayPauseIcon(state: state),
          ),
        ),
      ),
    );
  }
}

class PlayPauseIcon extends StatelessWidget {
  final MiniPlayerModel state;

  PlayPauseIcon({Key key, this.state}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        switch (state.playerState) {
          case PlayerStates.stopped:
            state.onPlay();
            break;
          case PlayerStates.playing:
            state.onPause();
            break;
          case PlayerStates.paused:
            state.onPlay();
            break;
          case PlayerStates.buffering:
            state.onPause();
            break;
        }
      },
      child: getIcon(state.playerState),
    );
  }

  Widget getIcon(PlayerStates playerState) {
    switch (playerState) {
      case PlayerStates.stopped:
        return Icon(Icons.play_circle_fill);
      case PlayerStates.playing:
        return Icon(Icons.pause);
      case PlayerStates.paused:
        return Icon(Icons.play_circle_fill);
      case PlayerStates.buffering:
        return Icon(Icons.pause);
      default:
        return Icon(Icons.play_circle_fill);
    }
  }
}

// DraggableScrollableSheet
// or BottomSheet ?
class PlayerBottomBar extends StatelessWidget {
  final double size;

  PlayerBottomBar({Key key, this.size}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MiniPlayer(size: size);
  }
}
