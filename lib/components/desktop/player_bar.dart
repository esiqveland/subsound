import 'package:async_redux/async_redux.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:subsound/components/covert_art.dart';
import 'package:subsound/components/miniplayer.dart';
import 'package:subsound/components/player.dart';
import 'package:subsound/state/appstate.dart';

class DesktopPlayerBar extends StatelessWidget {
  const DesktopPlayerBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 100.0,
      //color: Colors.amberAccent.withOpacity(0.5),
      child: DesktopMiniPlayer(
        height: 100.0,
        backgroundColor: Theme.of(context).backgroundColor,
        onTap: () {},
      ),
    );
  }
}

class _DesktopMiniPlayerModelFactory
    extends VmFactory<AppState, DesktopMiniPlayer> {
  _DesktopMiniPlayerModelFactory(DesktopMiniPlayer widget) : super(widget);

  @override
  MiniPlayerModel fromStore() {
    return MiniPlayerModel.from(state, dispatch);
  }
}

class DesktopMiniPlayer extends StatelessWidget {
  final double height;
  final Color backgroundColor;
  final Function onTap;

  DesktopMiniPlayer({
    Key? key,
    required this.height,
    required this.backgroundColor,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //final screenWidth = MediaQuery.of(context).size.width;
    final playerHeight = height - miniProgressBarHeight - bottomBorderSize;
    final mq = MediaQuery.of(context);

    return StoreConnector<AppState, MiniPlayerModel>(
      vm: () => _DesktopMiniPlayerModelFactory(this),
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
                child: Container(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: mq.size.width * 0.25,
                        child: Row(
                          children: [
                            DesktopMiniPlayerCover(
                              state: state,
                              playerHeight: playerHeight,
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.songTitle ?? 'Nothing playing',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.0),
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
                          ],
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Container(
                            child: Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.skip_previous),
                                  splashRadius: 12.0,
                                  iconSize: 26.0,
                                  onPressed: () {
                                    state.onPlayPrev();
                                  },
                                ),
                                PlayPauseIcon(state: state, iconSize: 32.0),
                                IconButton(
                                  icon: Icon(Icons.skip_next),
                                  splashRadius: 12.0,
                                  iconSize: 26.0,
                                  onPressed: () {
                                    state.onPlayNext();
                                  },
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(right: 5.0),
                            child: UpdatingPlayerSlider(
                              onSeek: state.onSeek,
                              onStartListen: state.onStartListen,
                              onStopListen: state.onStopListen,
                              size: MediaQuery.of(context).size.width * 0.4,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: mq.size.width * 0.25,
                        padding: EdgeInsets.only(right: 5.0),
                        child: PlayPauseIcon(state: state),
                      ),
                    ],
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

class DesktopMiniPlayerCover extends StatelessWidget {
  final MiniPlayerModel state;
  final double playerHeight;

  DesktopMiniPlayerCover({
    Key? key,
    required this.state,
    required this.playerHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final padding = EdgeInsets.all(14.0);

    final height = playerHeight - padding.top - padding.left;

    if (state.coverArtLink != null) {
      return Padding(
        padding: padding,
        child: CoverArtImage(
          state.coverArtLink,
          id: state.coverArtId,
          height: height,
          width: height,
          fit: BoxFit.fitHeight,
        ),
      );
    } else {
      return Padding(
        padding: EdgeInsets.only(left: 10.0),
        child: Icon(Icons.album),
      );
    }
  }
}
