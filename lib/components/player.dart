import 'dart:async';
import 'dart:developer';

import 'package:async_redux/async_redux.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:subsound/components/covert_art.dart';
import 'package:subsound/screens/login/album_page.dart';
import 'package:subsound/screens/login/myscaffold.dart';
import 'package:subsound/state/appcommands.dart';
import 'package:subsound/state/appstate.dart';
import 'package:subsound/state/playerstate.dart';
import 'package:subsound/subsonic/requests/get_album.dart';
import 'package:subsound/subsonic/requests/star.dart';
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
  final String contentType;
  final String fileExtension;
  final int fileSize;
  final Duration duration;
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
    this.contentType,
    this.fileExtension,
    this.fileSize,
    this.duration,
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
        contentType: s.contentType,
        fileExtension: s.suffix,
        fileSize: s.fileSize,
        duration: s.duration,
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
          contentType == other.contentType &&
          fileExtension == other.fileExtension &&
          fileSize == other.fileSize &&
          duration == other.duration &&
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
      duration.hashCode ^
      isStarred.hashCode;

  PlayerSong copy({
    bool isStarred,
  }) =>
      PlayerSong(
        id: id,
        songTitle: songTitle,
        artist: artist,
        album: album,
        artistId: artistId,
        albumId: albumId,
        coverArtId: coverArtId,
        coverArtLink: coverArtLink,
        songUrl: songUrl,
        contentType: contentType,
        fileExtension: fileExtension,
        fileSize: fileSize,
        duration: duration,
        isStarred: isStarred ?? this.isStarred,
      );

  @override
  String toString() {
    return 'PlayerSong{id: $id, songTitle: $songTitle, album: $album, artist: $artist, artistId: $artistId, albumId: $albumId, coverArtId: $coverArtId, coverArtLink: $coverArtLink, songUrl: $songUrl, isStarred: $isStarred}';
  }
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
        duration: Duration.zero,
        position: Duration.zero,
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

  @override
  String toString() {
    return 'PlayerState{current: $current, currentSong: $currentSong, queue: $queue, duration: $duration, position: $position}';
  }
}

class _PlayerViewModelFactory extends VmFactory<AppState, PlayerView> {
  _PlayerViewModelFactory(widget) : super(widget);

  @override
  PlayerViewModel fromStore() {
    return PlayerViewModel(
      songId: state.playerState.currentSong?.id,
      songTitle: state.playerState.currentSong?.songTitle,
      artistTitle: state.playerState.currentSong?.artist,
      albumTitle: state.playerState.currentSong?.album,
      albumId: state.playerState.currentSong?.albumId,
      coverArtLink: state.playerState.currentSong?.coverArtLink,
      coverArtId: state.playerState.currentSong?.coverArtId,
      isStarred: state.playerState.currentSong?.isStarred ?? false,
      duration: state.playerState.duration,
      position: state.playerState.position,
      playerState: state.playerState.current,
      onStar: (String id) => dispatch(StarIdCommand(SongId(songId: id))),
      onUnstar: (String id) => dispatch(UnstarIdCommand(SongId(songId: id))),
      onPlay: () => dispatch(PlayerCommandPlay()),
      onPause: () => dispatch(PlayerCommandPause()),
      onStartListen: (listener) =>
          dispatch(PlayerStartListenPlayerPosition(listener)),
      onStopListen: (listener) =>
          dispatch(PlayerStopListenPlayerPosition(listener)),
      onSeek: (val) => dispatch(PlayerCommandSeekTo(val)),
    );
  }
}

class PlayerViewModel extends Vm {
  final String songId;
  final String songTitle;
  final String artistTitle;
  final String albumTitle;
  final String albumId;
  final String coverArtLink;
  final String coverArtId;
  final bool isStarred;
  final Duration duration;
  final Duration position;
  final PlayerStates playerState;
  final Function(String) onStar;
  final Function(String) onUnstar;
  final Function onPlay;
  final Function onPause;
  final Function(PositionListener) onStartListen;
  final Function(PositionListener) onStopListen;
  final Function(int) onSeek;

  PlayerViewModel({
    @required this.songId,
    @required this.songTitle,
    @required this.artistTitle,
    @required this.albumTitle,
    @required this.albumId,
    @required this.coverArtLink,
    @required this.coverArtId,
    @required this.isStarred,
    @required this.duration,
    @required this.position,
    @required this.playerState,
    @required this.onStar,
    @required this.onUnstar,
    @required this.onPlay,
    @required this.onPause,
    @required this.onStartListen,
    @required this.onStopListen,
    @required this.onSeek,
  }) : super(equals: [
          songId,
          songTitle,
          artistTitle,
          albumTitle,
          albumId,
          coverArtLink,
          coverArtId,
          isStarred,
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
        vm: () => _PlayerViewModelFactory(this),
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
                    child: GestureDetector(
                      onTap: () {
                        if (vm.albumId != null) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  AlbumScreen(albumId: vm.albumId),
                            ),
                          );
                        }
                      },
                      child: FittedBox(
                        child: vm.coverArtLink != null
                            ? CoverArtImage(
                                vm.coverArtLink,
                                // height: 250,
                                // width: 250,
                                fit: BoxFit.cover,
                              )
                            : Icon(Icons.album),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.67,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SongTitle(songTitle: vm.songTitle),
                            SizedBox(height: 10.0),
                            ArtistTitle(artistName: vm.artistTitle),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (vm.isStarred) {
                            vm.onUnstar(vm.songId);
                          } else {
                            vm.onStar(vm.songId);
                          }
                        },
                        child: Icon(
                          vm.isStarred
                              ? Icons.star
                              : Icons.star_border_outlined,
                          color: Theme.of(context).accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    UpdatingPlayerSlider(
                      playerState: vm,
                      size: MediaQuery.of(context).size.width * 0.8,
                    ),
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
      songTitle ?? '',
      style: TextStyle(fontSize: 18.0),
      overflow: TextOverflow.fade,
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
      artistName ?? "",
      style: theme.textTheme.subtitle1.copyWith(
        fontSize: 12.0,
        color: Colors.white70,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}

class PlayerScreen extends StatelessWidget {
  static final String routeName = "/player";

  const PlayerScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "NOW PLAYING",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.0),
        ),
      ),
      body: (context) => PlayerView(),
      disableBottomBar: true,
    );
  }
}

class UpdatingPlayerSlider extends StatefulWidget {
  final PlayerViewModel playerState;
  final double size;

  const UpdatingPlayerSlider({
    Key key,
    this.playerState,
    this.size,
  }) : super(key: key);

  @override
  State<UpdatingPlayerSlider> createState() {
    return UpdatingPlayerSliderState();
  }
}

class UpdatingPlayerSliderState extends State<UpdatingPlayerSlider>
    implements PositionListener {
  StreamController<PositionUpdate> stream;

  @override
  void next(PositionUpdate pos) {
    stream.add(pos);
  }

  @override
  void reassemble() {
    super.reassemble();
    widget.playerState.onStopListen(this);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PositionUpdate>(
      stream: stream.stream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return PlayerSlider(
            playerState: widget.playerState,
            pos: snapshot.data,
            size: widget.size,
          );
        } else {
          return PlayerSlider(
            playerState: widget.playerState,
            pos: PositionUpdate(
              position: widget.playerState.position,
              duration: widget.playerState.duration,
            ),
            size: widget.size,
          );
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    stream = StreamController<PositionUpdate>(
      onListen: () {},
      onCancel: () {
        log('UpdatingPlayerSliderState: onCancel');
        widget.playerState.onStopListen(this);
      },
    );
    log('UpdatingPlayerSliderState: onInitListen');
    widget.playerState.onStartListen(this);
  }

  @override
  void dispose() {
    log('UpdatingPlayerSliderState: onFinishListen');
    widget.playerState.onStopListen(this);
    stream.close();
    super.dispose();
  }
}

class PlayerSlider extends StatelessWidget {
  final PlayerViewModel playerState;
  final PositionUpdate pos;
  final double size;

  PlayerSlider({
    Key key,
    this.playerState,
    this.pos,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final total = _getDuration(pos);
    final position = _getPosition(pos);

    return ProgressBar(
      onChanged: playerState.onSeek,
      position: position,
      total: total,
      size: size,
    );
  }

  static Duration _getDuration(PositionUpdate nextPos) {
    if (nextPos?.duration == null) {
      return Duration(seconds: 1);
    }
    return nextPos.duration;
  }

  static Duration _getPosition(PositionUpdate nextPos) {
    if (nextPos?.position == null) {
      return Duration(seconds: 0);
    }
    if (nextPos.position > nextPos.duration) {
      return nextPos.duration;
    } else {
      return nextPos.position;
    }
  }
}

class CachedSliderState extends State<CachedSlider> {
  double valueOverride;
  String labelOverride;

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderThemeData(
        trackShape: CustomTrackShape(),
      ),
      child: Slider.adaptive(
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
      ),
    );
  }
}

class CustomTrackShape extends RoundedRectSliderTrackShape {
  Rect getPreferredRect({
    @required RenderBox parentBox,
    Offset offset = Offset.zero,
    @required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight;
    final double trackLeft = offset.dx;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}

class CachedSlider extends StatefulWidget {
  final String label;
  final int value;
  final int max;
  final int divisions;
  final double width;
  final Function(int) onChanged;

  const CachedSlider({
    Key key,
    this.label,
    this.value,
    this.max,
    this.divisions,
    this.width,
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

    return SizedBox(
      width: size,
      child: Column(
        children: [
          CachedSlider(
            label: positionText,
            value: value,
            max: total.inSeconds,
            divisions: divisions,
            width: size,
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
