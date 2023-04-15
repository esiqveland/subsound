import 'dart:async';
import 'dart:developer';

import 'package:async_redux/async_redux.dart';
import 'package:flutter/material.dart';
import 'package:subsound/components/covert_art.dart';
import 'package:subsound/components/player.dart';
import 'package:subsound/state/appcommands.dart';
import 'package:subsound/state/appstate.dart';
import 'package:subsound/state/playerstate.dart';
import 'package:subsound/subsonic/requests/star.dart';

class PlayerBottomBar extends StatelessWidget {
  final double height;
  final Color backgroundColor;
  final Function onTap;

  PlayerBottomBar({
    Key? key,
    required this.height,
    required this.backgroundColor,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: MiniPlayer(
        height: height,
        backgroundColor: backgroundColor,
        onTap: onTap,
      ),
    );
  }
}

class _MiniPlayerModelFactory extends VmFactory<AppState, MiniPlayer, MiniPlayerModel> {
  _MiniPlayerModelFactory(MiniPlayer widget) : super(widget);

  @override
  MiniPlayerModel fromStore() {
    return MiniPlayerModel.from(state, dispatch);
  }
}

class MiniPlayerModel extends Vm {
  final bool hasCurrentSong;
  final String? songId;
  final String? songTitle;
  final String? artistTitle;
  final String? albumTitle;
  final String? coverArtLink;
  final String coverArtId;
  final Duration duration;
  final double playbackProgress;
  final double volume;
  final PlayerStates playerState;
  final Function onPlay;
  final Function onPause;
  final Function onPlayNext;
  final Function onPlayPrev;
  final Function(PositionListener) onStartListen;
  final Function(PositionListener) onStopListen;
  final Function(int) onSeek;
  final Function(double) onVolumeChanged;
  final Function(String) onStar;
  final Function(String) onUnstar;
  final bool isStarred;

  MiniPlayerModel({
    required this.hasCurrentSong,
    required this.songId,
    required this.songTitle,
    required this.artistTitle,
    required this.albumTitle,
    required this.coverArtLink,
    required this.coverArtId,
    required this.duration,
    required this.playbackProgress,
    required this.volume,
    required this.playerState,
    required this.onPlay,
    required this.onPause,
    required this.onPlayNext,
    required this.onPlayPrev,
    required this.onStartListen,
    required this.onStopListen,
    required this.onSeek,
    required this.onVolumeChanged,
    required this.onStar,
    required this.onUnstar,
    required this.isStarred,
  }) : super(equals: [
          hasCurrentSong,
          songId,
          artistTitle ?? '',
          songTitle ?? '',
          albumTitle ?? '',
          coverArtLink ?? '',
          coverArtId,
          duration,
          volume,
          playerState,
          isStarred,
        ]);

  static MiniPlayerModel from(AppState state, Dispatch<AppState> dispatch) {
    final pos = state.playerState.position.inMilliseconds;
    final durSafe = state.playerState.duration.inMilliseconds;
    final dur = durSafe == 0 ? 1 : durSafe;
    final playbackProgress = pos / dur;
    final currentSong = state.playerState.currentSong;

    return MiniPlayerModel(
      hasCurrentSong: currentSong != null,
      songId: currentSong?.id ?? '',
      songTitle: currentSong?.songTitle ?? '',
      artistTitle: currentSong?.artist ?? '',
      albumTitle: currentSong?.album ?? '',
      coverArtLink: currentSong?.coverArtLink ?? '',
      coverArtId: currentSong?.coverArtId ?? '',
      duration: state.playerState.duration,
      playbackProgress: playbackProgress,
      volume: state.playerState.volume,
      playerState: state.playerState.current,
      onPlay: () => dispatch(PlayerCommandPlay()),
      onPause: () => dispatch(PlayerCommandPause()),
      onPlayNext: () => dispatch(PlayerCommandSkipNext()),
      onPlayPrev: () => dispatch(PlayerCommandSkipPrev()),
      onStartListen: (listener) =>
          dispatch(PlayerStartListenPlayerPosition(listener)),
      onStopListen: (listener) =>
          dispatch(PlayerStopListenPlayerPosition(listener)),
      onSeek: (seekToPosition) => dispatch(PlayerCommandSeekTo(seekToPosition)),
      onVolumeChanged: (next) => dispatch(PlayerCommandSetVolume(next)),
      onStar: (next) => dispatch(StarIdCommand(SongId(songId: next))),
      onUnstar: (next) => dispatch(UnstarIdCommand(SongId(songId: next))),
      isStarred: currentSong?.isStarred ?? false,
    );
  }
}

class MiniPlayerProgressBar extends StatefulWidget {
  final double height;
  final Function(PositionListener) onInitListen;
  final Function(PositionListener) onFinishListen;

  MiniPlayerProgressBar({
    Key? key,
    required this.height,
    required this.onInitListen,
    required this.onFinishListen,
  }) : super(key: key);

  @override
  State<MiniPlayerProgressBar> createState() {
    return MiniPlayerProgressBarState();
  }
}

class MiniPlayerProgressBarState extends State<MiniPlayerProgressBar>
    implements PositionListener {
  late StreamController<PositionUpdate> stream;

  @override
  void next(PositionUpdate pos) {
    stream.add(pos);
  }

  @override
  void reassemble() {
    super.reassemble();
    widget.onFinishListen(this);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return StreamBuilder<PositionUpdate>(
      stream: stream.stream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final next = snapshot.data;
          final pos = next?.position.inMilliseconds ?? 0;
          final durSafe = next?.duration.inMilliseconds ?? 1;
          final dur = durSafe == 0 ? 1 : durSafe;
          final playbackProgress = pos / dur;

          return Stack(
            children: [
              Container(
                padding: EdgeInsets.all(0),
                height: widget.height,
                color: Colors.white38,
              ),
              Container(
                color: Colors.white,
                height: widget.height,
                width: screenWidth * playbackProgress,
              ),
            ],
          );
        } else {
          return Stack(
            children: [
              Container(
                padding: EdgeInsets.all(0),
                height: widget.height,
                color: Colors.white38,
              ),
              Container(
                color: Colors.white,
                height: widget.height,
                width: screenWidth * 0.0,
              ),
            ],
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
        widget.onFinishListen(this);
      },
    );
    log('onInitListen');
    widget.onInitListen(this);
  }

  @override
  void dispose() {
    log('onFinishListen');
    stream.close();
    widget.onFinishListen(this);
    super.dispose();
  }
}

const miniProgressBarHeight = 2.0;
const bottomBorderSize = 1.0;

class MiniPlayer extends StatelessWidget {
  final double height;
  final Color backgroundColor;
  final Function onTap;

  MiniPlayer({
    Key? key,
    required this.height,
    required this.backgroundColor,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //final screenWidth = MediaQuery.of(context).size.width;
    final playerHeight = height - miniProgressBarHeight - bottomBorderSize;

    return StoreConnector<AppState, MiniPlayerModel>(
      vm: () => _MiniPlayerModelFactory(this),
      builder: (context, state) => SizedBox(
        height: height,
        child: Container(
          decoration: BoxDecoration(
              // color: Colors.black12,
              // color: Colors.pinkAccent,
              border: Border(
                  bottom: BorderSide(
            //color: Colors.black,
            width: bottomBorderSize,
          ))),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              MiniPlayerProgressBar(
                height: miniProgressBarHeight,
                onInitListen: state.onStartListen,
                onFinishListen: state.onStopListen,
              ),
              SizedBox(
                height: playerHeight,
                child: InkWell(
                  onTap: () {
                    onTap();
                  },
                  child: Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        state.coverArtLink != null
                            ? CoverArtImage(
                                state.coverArtLink,
                                id: state.coverArtId,
                                height: playerHeight,
                                width: playerHeight,
                                fit: BoxFit.fitHeight,
                              )
                            : Padding(
                                padding: EdgeInsets.only(left: 10.0),
                                child: Icon(Icons.album),
                              ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(
                              state.songTitle ?? 'Nothing playing',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12.0),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              state.artistTitle ?? 'Artistic',
                              style: TextStyle(
                                  fontWeight: FontWeight.normal,
                                  fontSize: 11.0),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.only(right: 5.0),
                          child: PlayPauseIcon(state: state),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlayPauseIcon extends StatelessWidget {
  final MiniPlayerModel state;
  final double? iconSize;

  PlayPauseIcon({Key? key, required this.state, this.iconSize})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: state.hasCurrentSong
          ? () {
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
            }
          : null,
      splashRadius: 16.0,
      icon: getIcon(state.playerState),
      iconSize: iconSize,
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
        return Icon(Icons.refresh);
      default:
        return Icon(Icons.play_circle_fill);
    }
  }
}
