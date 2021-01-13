import 'package:async_redux/async_redux.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:subsound/components/covert_art.dart';
import 'package:subsound/screens/login/myscaffold.dart';
import 'package:subsound/state/appstate.dart';
import 'package:subsound/state/playerstate.dart';
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
      coverArtLink: state.playerState.currentSong?.coverArtLink,
      coverArtId: state.playerState.currentSong?.coverArtId,
      duration: state.playerState.duration,
      position: state.playerState.position,
      playerState: state.playerState.current,
      onPlay: () => dispatch(PlayerCommandPlay()),
      onPause: () => dispatch(PlayerCommandPause()),
      onSeek: (val) => dispatch(PlayerCommandSeekTo(val)),
    );
  }
}

class PlayerViewModel extends Vm {
  final String songTitle;
  final String artistTitle;
  final String albumTitle;
  final String coverArtLink;
  final String coverArtId;
  final Duration duration;
  final Duration position;
  final PlayerStates playerState;
  final Function onPlay;
  final Function onPause;
  final Function(int) onSeek;

  PlayerViewModel({
    @required this.songTitle,
    @required this.artistTitle,
    @required this.albumTitle,
    @required this.coverArtLink,
    @required this.coverArtId,
    @required this.duration,
    @required this.position,
    @required this.playerState,
    @required this.onPlay,
    @required this.onPause,
    @required this.onSeek,
  }) : super(equals: [
          artistTitle,
          songTitle,
          albumTitle,
          coverArtLink,
          coverArtId,
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
      child: StoreConnector<AppState, PlayerViewModel>(
        vm: _PlayerViewModelFactory(this),
        builder: (context, vm) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints.tightForFinite(width: 400),
            //color: Colors.tealAccent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: 100,
                    maxHeight: MediaQuery.of(context).size.width * 0.8,
                    minWidth: 100,
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                  ),
                  child: SizedBox.expand(
                    child: FittedBox(
                      child: vm.coverArtLink != null
                          ? CoverArtImage(
                              vm.coverArtLink,
                              // height: 250,
                              // width: 250,
                              fit: BoxFit.cover,
                            )
                          : Padding(
                              padding: EdgeInsets.only(left: 10.0),
                              child: Icon(Icons.album),
                            ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SongTitle(songTitle: vm.songTitle),
                  ],
                ),
                SizedBox(height: 10.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ArtistTitle(artistName: vm.artistTitle),
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
  final String songTitle;

  const SongTitle({Key key, this.songTitle}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      songTitle ?? 'Fdasfdsafdsafdsafdsz',
      style: TextStyle(fontSize: 18.0),
    );
  }
}

class ArtistTitle extends StatelessWidget {
  final String artistName;

  const ArtistTitle({Key key, this.artistName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      artistName ?? "Bklbjxcjblkvcxjblkvcxjkl",
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
      disableBottomBar: true,
    );
  }
}

class PlayerSlider extends StatelessWidget {
  final PlayerViewModel playerState;
  final double size;

  PlayerSlider({
    Key key,
    this.playerState,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final total = _getMax(playerState);
    final position = _getPosition(playerState);

    return ProgressBar(
      onChanged: playerState.onSeek,
      position: position,
      total: total,
      size: size,
    );
  }

  static Duration _getMax(PlayerViewModel playerState) {
    if (playerState == null || playerState.duration == null) {
      return Duration(seconds: 279);
    }
    return playerState.duration;
  }

  static Duration _getPosition(PlayerViewModel playerState) {
    if (playerState == null || playerState.position == null) {
      return Duration(seconds: 100);
    }
    return playerState.position;
  }
}

class CachedSliderState extends State<CachedSlider> {
  double valueOverride;
  String labelOverride;

  @override
  Widget build(BuildContext context) {
    return Slider.adaptive(
      activeColor: Colors.tealAccent,
      label: labelOverride ?? widget.label,
      min: 0.0,
      max: widget.max.toDouble(),
      value: valueOverride ?? widget.value.toDouble(),
      divisions: widget.divisions,
      onChangeEnd: (double newValue) {
        final nextValue = newValue.round();
        widget.onChanged(nextValue);
        this.setState(() {
          this.valueOverride = null;
          this.labelOverride = null;
        });
      },
      onChanged: (double newValue) {
        final nextValue = newValue.round();
        this.setState(() {
          this.valueOverride = newValue;
          this.labelOverride = formatDuration(Duration(seconds: nextValue));
        });
      },
      semanticFormatterCallback: (double newValue) {
        return formatDuration(Duration(seconds: newValue.round()));
      },
    );
  }
}

class CachedSlider extends StatefulWidget {
  final String label;
  final int value;
  final int max;
  final int divisions;
  final Function(int) onChanged;

  const CachedSlider({
    Key key,
    this.label,
    this.value,
    this.max,
    this.divisions,
    this.onChanged,
  }) : super(key: key);

  @override
  State<CachedSlider> createState() {
    return CachedSliderState();
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
    final value = position?.inSeconds ?? 1;

    return Container(
      width: size,
      child: Column(
        children: [
          CachedSlider(
            label: positionText,
            value: value,
            max: total.inSeconds,
            divisions: divisions,
            onChanged: onChanged,
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
  final PlayerViewModel state;
  final double size;

  const PlayButton({
    Key key,
    this.state,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
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
      splashRadius: 40.0,
      iconSize: size,
      hoverColor: Colors.tealAccent,
      icon: _getIcon(state.playerState),
    );
  }

  _getIcon(PlayerStates current) {
    if (current == null) {
      return Icon(Icons.play_arrow, size: size);
    }
    if (current == PlayerStates.playing) {
      return Icon(Icons.pause, size: size);
    }
    if (current == PlayerStates.paused) {
      return Icon(Icons.play_arrow, size: size);
    }
    if (current == PlayerStates.stopped) {
      return Icon(Icons.play_arrow, size: size);
    }
    if (current == PlayerStates.buffering) {
      return Icon(Icons.pause, size: size);
    }
    return Icon(Icons.play_arrow, size: size);
  }
}
