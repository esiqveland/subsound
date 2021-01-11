import 'package:async_redux/async_redux.dart';
import 'package:flutter/material.dart';
import 'package:subsound/components/covert_art.dart';
import 'package:subsound/components/player.dart';
import 'package:subsound/state/appstate.dart';

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

class _MiniPlayerModelFactory extends VmFactory<AppState, MiniPlayer> {
  _MiniPlayerModelFactory(widget) : super(widget);

  @override
  MiniPlayerModel fromStore() {
    return MiniPlayerModel(
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
          child: Container(
            child: Stack(
              children: [
                Positioned(
                    top: 0.0,
                    left: 0.0,
                    child: CoverArtImage(
                      state.coverArtLink,
                      height: size,
                      fit: BoxFit.scaleDown,
                    )),
              ],
            ),
            // ListTile(
            //   onTap: () {
            //     showModalBottomSheet(
            //       context: context,
            //       builder: (context) => PlayerView(),
            //       enableDrag: true,
            //       isDismissible: false,
            //     );
            //   },
            //   visualDensity: VisualDensity(horizontal: 0, vertical: 0),
            //   dense: true,
            //   isThreeLine: true,
            //   leading: CoverArtImage(
            //     state.coverArtLink,
            //     height: 40.0,
            //     fit: BoxFit.scaleDown,
            //   ),
            //   title: Text(
            //     state.songTitle ?? 'Nothing playing',
            //     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0),
            //     overflow: TextOverflow.ellipsis,
            //   ),
            //   subtitle: Text(
            //     state.artistTitle ?? '',
            //     style: TextStyle(fontWeight: FontWeight.normal, fontSize: 12.0),
            //     overflow: TextOverflow.ellipsis,
            //   ),
            //   trailing: PlayPauseIcon(state: state),
            // ),
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
