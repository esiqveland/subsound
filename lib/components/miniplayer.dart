import 'package:async_redux/async_redux.dart';
import 'package:flutter/material.dart';
import 'package:subsound/components/covert_art.dart';
import 'package:subsound/components/player.dart';
import 'package:subsound/state/appstate.dart';
import 'package:subsound/state/playerstate.dart';

// DraggableScrollableSheet
// or BottomSheet ?
class PlayerBottomBar extends StatelessWidget {
  final double height;

  PlayerBottomBar({Key key, this.height}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MiniPlayer(height: height);
  }
}

class _MiniPlayerModelFactory extends VmFactory<AppState, MiniPlayer> {
  _MiniPlayerModelFactory(widget) : super(widget);

  @override
  MiniPlayerModel fromStore() {
    final pos = state.playerState.position?.inMilliseconds ?? 0;
    final durSafe = state.playerState.duration?.inMilliseconds ?? 1;
    final dur = durSafe == 0 ? 1 : durSafe;
    final playbackProgress = pos / dur;

    return MiniPlayerModel(
      songTitle: state.playerState.currentSong?.songTitle,
      artistTitle: state.playerState.currentSong?.artist,
      albumTitle: state.playerState.currentSong?.album,
      coverArtLink: state.playerState.currentSong?.coverArtLink,
      coverArtId: state.playerState.currentSong?.coverArtId,
      duration: state.playerState.duration,
      position: state.playerState.position,
      playbackProgress: playbackProgress,
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
  final String coverArtLink;
  final String coverArtId;
  final Duration duration;
  final Duration position;
  final double playbackProgress;
  final PlayerStates playerState;
  final Function onPlay;
  final Function onPause;

  MiniPlayerModel({
    @required this.songTitle,
    @required this.artistTitle,
    @required this.albumTitle,
    @required this.coverArtLink,
    @required this.coverArtId,
    @required this.duration,
    @required this.position,
    @required this.playbackProgress,
    @required this.playerState,
    @required this.onPlay,
    @required this.onPause,
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

const miniProgressBarHeight = 2.0;

class MiniPlayer extends StatelessWidget {
  final double height;

  const MiniPlayer({Key key, this.height}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final playerHeight = height - miniProgressBarHeight;

    return SizedBox(
      height: height,
      child: Container(
        // color: Colors.pinkAccent,
        child: StoreConnector<AppState, MiniPlayerModel>(
          vm: _MiniPlayerModelFactory(this),
          builder: (context, state) => Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    padding: EdgeInsets.all(0),
                    height: miniProgressBarHeight,
                    color: Colors.white38,
                  ),
                  Container(
                    color: Colors.white,
                    height: miniProgressBarHeight,
                    width: screenWidth * state.playbackProgress,
                  ),
                ],
              ),
              SizedBox(
                height: playerHeight,
                child: InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => PlayerView(),
                      enableDrag: true,
                      isDismissible: false,
                    );
                  },
                  child: Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        state.coverArtLink != null
                            ? CoverArtImage(
                                state.coverArtLink,
                                height: playerHeight,
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

  PlayPauseIcon({Key key, this.state}) : super(key: key);

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
      splashRadius: 16.0,
      icon: getIcon(state.playerState),
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
