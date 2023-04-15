import 'dart:async';
import 'dart:developer';

import 'package:async_redux/async_redux.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:subsound/components/covert_art.dart';
import 'package:subsound/components/miniplayer.dart';
import 'package:subsound/state/appstate.dart';
import 'package:subsound/state/playerstate.dart';
import 'package:subsound/utils/duration.dart';

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
        // backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        backgroundColor: Color(0xFF121212),
        //backgroundColor: Colors.amberAccent.withOpacity(0.5),
        onTap: () {},
      ),
    );
  }
}

class _DesktopMiniPlayerModelFactory
    extends VmFactory<AppState, DesktopMiniPlayer, MiniPlayerModel> {
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
    final totalWidth = mq.size.width - bottomBorderSize * 2;
    final widthLeft = totalWidth / 3;
    final widthCenter = totalWidth / 3;
    final widthRight = totalWidth / 3;

    return StoreConnector<AppState, MiniPlayerModel>(
      vm: () => _DesktopMiniPlayerModelFactory(this),
      builder: (context, state) => SizedBox(
        height: height,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(width: bottomBorderSize),
              right: BorderSide(width: bottomBorderSize),
              bottom: BorderSide(width: bottomBorderSize),
            ),
            color: backgroundColor,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
                        width: widthLeft,
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
                                    fontSize: 12.0,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  state.artistTitle ?? 'Artistic',
                                  style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 11.0,
                                    color: Theme.of(context).textTheme.caption?.color,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: GestureDetector(
                                onTap: state.hasCurrentSong
                                    ? () {
                                        if (state.songId != null) {
                                          if (state.isStarred) {
                                            state.onUnstar(state.songId!);
                                          } else {
                                            state.onStar(state.songId!);
                                          }
                                        }
                                      }
                                    : null,
                                child: Icon(
                                  state.isStarred
                                      ? Icons.star
                                      : Icons.star_border_outlined,
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: widthCenter,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.skip_previous),
                                    splashRadius: 12.0,
                                    iconSize: 26.0,
                                    onPressed: state.hasCurrentSong
                                        ? () {
                                            state.onPlayPrev();
                                          }
                                        : null,
                                  ),
                                  PlayPauseIcon(state: state, iconSize: 32.0),
                                  IconButton(
                                    icon: Icon(Icons.skip_next),
                                    splashRadius: 12.0,
                                    iconSize: 26.0,
                                    onPressed: state.hasCurrentSong
                                        ? () {
                                            state.onPlayNext();
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              child: UpdatingPlayerBarSlider(
                                onSeek: state.onSeek,
                                onStartListen: state.onStartListen,
                                onStopListen: state.onStopListen,
                                size: widthCenter - 10.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: widthRight,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: EdgeInsets.only(right: 10),
                              child: VolumeSliderIcon(
                                volume: state.volume,
                                onChange: state.onVolumeChanged,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.only(right: 20.0),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: 76.0,
                                ),
                                child: VolumeWidget(
                                  volume: state.volume,
                                  onChanged: state.onVolumeChanged,
                                ),
                              ),
                            )
                          ],
                        ),
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

class VolumeSliderIcon extends StatefulWidget {
  final double volume;
  final Function(double) onChange;

  const VolumeSliderIcon({
    Key? key,
    required this.volume,
    required this.onChange,
  }) : super(key: key);

  @override
  State<VolumeSliderIcon> createState() => _VolumeSliderIconState();
}

class _VolumeSliderIconState extends State<VolumeSliderIcon> {
  double? storedVolume;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: () {
            if (widget.volume < 0.001) {
              if (storedVolume != null) {
                final setVolume = storedVolume!;
                setState(() {
                  storedVolume = null;
                });
                widget.onChange(setVolume);
              } else {
                setState(() {
                  storedVolume = null;
                });
                widget.onChange(1.0);
              }
            } else {
              final current = widget.volume;
              setState(() {
                storedVolume = current;
              });
              widget.onChange(0.0);
            }
          },
          child: Icon(
            getIcon(widget.volume),
            size: 20,
            color: Theme.of(context).textTheme.caption!.color,
            semanticLabel: 'Volume control',
          ),
        ),
      ],
    );
  }

  IconData getIcon(double volume) {
    if (volume <= 0.01) {
      return Icons.volume_off;
    } else if (volume < 0.3) {
      return Icons.volume_mute;
    } else if (volume < 0.6) {
      return Icons.volume_down;
    } else if (volume < 0.95) {
      return Icons.volume_up;
    } else {
      return Icons.volume_up_outlined;
    }
  }
}

class VolumeWidget extends StatelessWidget {
  final double volume;
  final Function(double) onChanged;

  const VolumeWidget({
    Key? key,
    required this.volume,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return VolumeSlider(
      volume: volume,
      onChanged: onChanged,
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
    final link = state.coverArtLink;

    if (link != null && link.isNotEmpty) {
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
        child: Icon(
          Icons.album,
          size: height,
          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.4),
        ),
      );
    }
  }
}

class VolumeSlider extends StatelessWidget {
  final double volume;
  final Function(double) onChanged;

  const VolumeSlider({
    Key? key,
    required this.volume,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 2.0,
        trackShape: CustomTrackShape(),
        thumbShape: RoundSliderThumbShape(
          enabledThumbRadius: 5.0,
          pressedElevation: 4.0,
          elevation: 2.0,
        ),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 8.0),
        overlayColor: Theme.of(context).primaryColor.withOpacity(0.4),
        thumbColor: Theme.of(context).primaryColor,
        activeTrackColor: Theme.of(context).primaryColor,
        inactiveTrackColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withOpacity(0.4)
            : Colors.black.withOpacity(0.2),
      ),
      child: Container(
        child: Slider(
          value: volume,
          onChanged: onChanged,
          max: 1.0,
          min: 0.0,
        ),
      ),
    );
  }
}

class UpdatingPlayerBarSlider extends StatefulWidget {
  final double size;
  final Function(PositionListener) onStartListen;
  final Function(PositionListener) onStopListen;
  final Function(int) onSeek;

  UpdatingPlayerBarSlider({
    Key? key,
    required this.size,
    required this.onSeek,
    required this.onStartListen,
    required this.onStopListen,
  }) : super(key: key);

  @override
  State<UpdatingPlayerBarSlider> createState() {
    return UpdatingPlayerBarSliderState();
  }
}

class UpdatingPlayerBarSliderState extends State<UpdatingPlayerBarSlider>
    implements PositionListener {
  late StreamController<PositionUpdate> stream;

  @override
  void next(PositionUpdate pos) {
    stream.add(pos);
  }

  @override
  void reassemble() {
    super.reassemble();
    widget.onStopListen(this);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PositionUpdate>(
      stream: stream.stream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return PlayerSlider(
            onSeek: widget.onSeek,
            pos: snapshot.data!,
            size: widget.size,
          );
        } else {
          return PlayerSlider(
            onSeek: widget.onSeek,
            pos: PositionUpdate(
              position: Duration.zero,
              duration: Duration(milliseconds: 1),
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
    widget.onStartListen(this);
    stream = StreamController<PositionUpdate>(
      onListen: () {
        log('UpdatingPlayerSliderState: onListen');
        widget.onStartListen(this);
      },
      onCancel: () {
        log('UpdatingPlayerSliderState: onCancel');
        widget.onStopListen(this);
      },
      onPause: () {
        log('UpdatingPlayerSliderState: onPause');
        widget.onStopListen(this);
      },
      onResume: () {
        log('UpdatingPlayerSliderState: onResume');
        widget.onStartListen(this);
      },
    );
  }

  @override
  void dispose() {
    log('UpdatingPlayerSliderState: onFinishListen');
    widget.onStopListen(this);
    stream.close();
    super.dispose();
  }
}

class PlayerSlider extends StatelessWidget {
  final Function(int) onSeek;
  final PositionUpdate pos;
  final double size;

  PlayerSlider({
    Key? key,
    required this.onSeek,
    required this.pos,
    required this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final total = _getDuration(pos);
    final position = _getPosition(pos);

    return ProgressBar(
      onChanged: onSeek,
      position: position,
      total: total,
      width: size,
    );
  }

  static Duration _getDuration(PositionUpdate nextPos) {
    if (nextPos.duration.inMilliseconds == 0) {
      // avoid division by zero
      return Duration(seconds: 1);
    }
    return nextPos.duration;
  }

  static Duration _getPosition(PositionUpdate nextPos) {
    if (nextPos.position == Duration.zero) {
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
  double? valueOverride;
  String? labelOverride;

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 2.0,
        trackShape: CustomTrackShape(),
        thumbShape: RoundSliderThumbShape(
          enabledThumbRadius: 5.0,
          pressedElevation: 4.0,
          elevation: 2.0,
        ),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 8.0),
        overlayColor: Theme.of(context).colorScheme.secondary.withOpacity(0.4),
        thumbColor: Theme.of(context).colorScheme.secondary,
        activeTrackColor: Theme.of(context).colorScheme.secondary,
        inactiveTrackColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withOpacity(0.4)
            : Colors.black.withOpacity(0.2),
      ),
      child: Slider.adaptive(
        label: labelOverride ?? widget.label,
        min: 0.0,
        max: widget.max.toDouble(),
        value: valueOverride ?? widget.value.toDouble(),
        divisions: widget.divisions,
        onChangeEnd: (double newValue) {
          final nextValue = newValue.round();
          widget.onChanged(nextValue);
          setState(() {
            valueOverride = null;
            labelOverride = null;
          });
        },
        onChanged: (double newValue) {
          final nextValue = newValue.round();
          setState(() {
            valueOverride = newValue;
            labelOverride = formatDuration(Duration(seconds: nextValue));
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
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 0;
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
    Key? key,
    required this.label,
    required this.value,
    required this.max,
    required this.divisions,
    required this.width,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<CachedSlider> createState() {
    return CachedSliderState();
  }
}

class ProgressBar extends StatelessWidget {
  final Duration total;
  final Duration position;
  final double width;
  final Function(int) onChanged;
  final double spacerWidth = 10.0;

  ProgressBar({
    Key? key,
    required this.onChanged,
    required this.total,
    required this.position,
    required this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var positionText = formatDuration(position);
    var remaining =
        Duration(microseconds: total.inMicroseconds - position.inMicroseconds);
    var remainingText = "-" + formatDuration(remaining);

    final divisions = total.inSeconds < 1 ? 1 : total.inSeconds;
    final value = position.inSeconds;

    return SizedBox(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(positionText, style: Theme.of(context).textTheme.caption),
          SizedBox(width: spacerWidth),
          Expanded(
            child: CachedSlider(
              label: positionText,
              value: value,
              max: total.inSeconds,
              divisions: divisions,
              width: width,
              onChanged: onChanged,
            ),
          ),
          SizedBox(width: spacerWidth),
          Text(remainingText, style: Theme.of(context).textTheme.caption),
        ],
      ),
    );
  }
}
