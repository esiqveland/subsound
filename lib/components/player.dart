import 'dart:async';
import 'dart:developer';

import 'package:async_redux/async_redux.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:subsound/components/covert_art.dart';
import 'package:subsound/screens/login/album_page.dart';
import 'package:subsound/screens/login/myscaffold.dart';
import 'package:subsound/state/appcommands.dart';
import 'package:subsound/state/appstate.dart';
import 'package:subsound/state/player_task.dart';
import 'package:subsound/state/playerstate.dart';
import 'package:subsound/state/queue.dart';
import 'package:subsound/storage/cache.dart';
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
  final String? coverArtLink;
  final String songUrl;
  final String contentType;
  final String fileExtension;
  final int fileSize;
  final Duration duration;
  final bool isStarred;

  PlayerSong({
    required this.id,
    required this.songTitle,
    required this.artist,
    required this.album,
    required this.artistId,
    required this.albumId,
    required this.coverArtId,
    this.coverArtLink,
    required this.songUrl,
    required this.contentType,
    required this.fileExtension,
    required this.fileSize,
    required this.duration,
    this.isStarred = false,
  });

  static PlayerSong from(SongResult s, [bool? isStarred]) => PlayerSong(
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
        isStarred: isStarred ?? s.starred,
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
    bool? isStarred,
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
    return 'PlayerSong{id: $id, songTitle: $songTitle, format=$fileExtension,}';
  }

  MediaItem toMediaItem() {
    return asMediaItem(this);
  }

  static MediaItem asMediaItem(PlayerSong song) {
    SongMetadata meta = SongMetadata(
      songId: song.id,
      songUrl: song.songUrl,
      fileExtension: song.fileExtension,
      fileSize: song.fileSize,
      contentType: song.contentType,
    );
    final playItem = MediaItem(
      id: song.songUrl,
      artist: song.artist,
      album: song.album,
      title: song.songTitle,
      displayTitle: song.songTitle,
      displaySubtitle: song.artist,
      artUri: song.coverArtLink != null ? Uri.parse(song.coverArtLink!) : null,
      duration: song.duration.inSeconds > 0 ? song.duration : Duration.zero,
      extras: {},
    ).setSongMetadata(meta);

    return playItem;
  }

  // static PlayerSong fromMediaItem(MediaItem item) {
  //   var meta = item.getSongMetadata();
  //   return PlayerSong(
  //     id: item.id,
  //     songTitle: item.id,
  //     artist: item.artist ?? '',
  //     album: item.album ?? '',
  //     artistId: item.artist,
  //     albumId: albumId,
  //     coverArtId: coverArtId,
  //     songUrl: songUrl,
  //     contentType: contentType,
  //     fileExtension: fileExtension,
  //     fileSize: fileSize,
  //     duration: duration,
  //   );
  // }
}

enum PlayerStates { stopped, playing, paused, buffering }
enum ShuffleMode { none, shuffle }

class PlayerState {
  final PlayerStates current;
  final PlayerSong? currentSong;
  final Queue queue;
  final Duration duration;
  final Duration position;
  final ShuffleMode shuffleMode;
  final double volume;

  PlayerState({
    required this.current,
    this.currentSong,
    required this.queue,
    required this.duration,
    required this.position,
    required this.shuffleMode,
    required this.volume,
  });

  bool get isPlaying => current == PlayerStates.playing;

  bool get isPaused =>
      current == PlayerStates.paused || current == PlayerStates.buffering;

  bool get isStopped => current == PlayerStates.stopped;

  PlayerState copy({
    PlayerStates? current,
    PlayerSong? currentSong,
    Queue? queue,
    Duration? duration,
    Duration? position,
    ShuffleMode? shuffleMode,
    double? volume,
  }) =>
      PlayerState(
        current: current ?? this.current,
        currentSong: currentSong ?? this.currentSong,
        queue: queue ?? this.queue,
        duration: duration ?? this.duration,
        position: position ?? this.position,
        shuffleMode: shuffleMode ?? this.shuffleMode,
        volume: volume ?? this.volume,
      );

  static PlayerState initialState() => PlayerState(
        current: PlayerStates.stopped,
        currentSong: null,
        duration: Duration.zero,
        position: Duration.zero,
        queue: Queue([]),
        shuffleMode: ShuffleMode.none,
        volume: 1.0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerState &&
          runtimeType == other.runtimeType &&
          current == other.current &&
          currentSong == other.currentSong &&
          queue == other.queue &&
          shuffleMode == other.shuffleMode &&
          duration == other.duration &&
          position == other.position;

  @override
  int get hashCode =>
      current.hashCode ^
      currentSong.hashCode ^
      queue.hashCode ^
      duration.hashCode ^
      position.hashCode ^
      shuffleMode.hashCode;

  @override
  String toString() {
    return 'PlayerState{current: $current, currentSong: $currentSong, queue: ${queue.length}, duration: $duration, position: $position, shuffleMode: ${describeEnum(shuffleMode)}';
  }
}

class _PlayerViewModelFactory extends VmFactory<AppState, PlayerView, PlayerViewModel> {
  _PlayerViewModelFactory(PlayerView widget) : super(widget);

  @override
  PlayerViewModel fromStore() {
    return PlayerViewModel(
      songId: state.playerState.currentSong?.id ?? '',
      songTitle: state.playerState.currentSong?.songTitle ?? '',
      artistTitle: state.playerState.currentSong?.artist ?? '',
      albumTitle: state.playerState.currentSong?.album ?? '',
      albumId: state.playerState.currentSong?.albumId ?? '',
      coverArtLink: state.playerState.currentSong?.coverArtLink ?? '',
      coverArtId: state.playerState.currentSong?.coverArtId ?? '',
      isStarred: state.playerState.currentSong?.isStarred ?? false,
      duration: state.playerState.duration,
      position: state.playerState.position,
      playerState: state.playerState.current,
      onStar: (String id) => dispatch(StarIdCommand(SongId(songId: id))),
      onUnstar: (String id) => dispatch(UnstarIdCommand(SongId(songId: id))),
      onPlay: () => dispatch(PlayerCommandPlay()),
      onPause: () => dispatch(PlayerCommandPause()),
      onPlayNext: () => dispatch(PlayerCommandSkipNext()),
      onPlayPrev: () => dispatch(PlayerCommandSkipPrev()),
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
  final String? coverArtLink;
  final String coverArtId;
  final bool isStarred;
  final Duration duration;
  final Duration position;
  final PlayerStates playerState;
  final Function(String) onStar;
  final Function(String) onUnstar;
  final Function onPlay;
  final Function onPause;
  final Function onPlayNext;
  final Function onPlayPrev;
  final Function(PositionListener) onStartListen;
  final Function(PositionListener) onStopListen;
  final Function(int) onSeek;

  PlayerViewModel({
    required this.songId,
    required this.songTitle,
    required this.artistTitle,
    required this.albumTitle,
    required this.albumId,
    this.coverArtLink,
    required this.coverArtId,
    required this.isStarred,
    required this.duration,
    required this.position,
    required this.playerState,
    required this.onStar,
    required this.onUnstar,
    required this.onPlay,
    required this.onPause,
    required this.onPlayNext,
    required this.onPlayPrev,
    required this.onStartListen,
    required this.onStopListen,
    required this.onSeek,
  }) : super(equals: [
          songId,
          songTitle,
          artistTitle,
          albumTitle,
          albumId,
          coverArtLink ?? '',
          coverArtId,
          isStarred,
          duration,
          position,
          playerState,
        ]);
}

class PlayerView extends StatelessWidget {
  final Widget? header;
  final Color? backgroundColor;

  const PlayerView({
    Key? key,
    this.header,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: StoreConnector<AppState, PlayerViewModel>(
        vm: () => _PlayerViewModelFactory(this),
        builder: (context, vm) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints.tightForFinite(width: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (header != null) header!,
                Column(
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
                            if (vm.albumId.isNotEmpty) {
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
                                    id: vm.coverArtId,
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
                                SizedBox(height: 12.0),
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
                              color: Theme.of(context).colorScheme.secondary,
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
                          onSeek: vm.onSeek,
                          size: MediaQuery.of(context).size.width * 0.8,
                          onStartListen: vm.onStartListen,
                          onStopListen: vm.onStopListen,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.skip_previous),
                          iconSize: 42.0,
                          onPressed: () {
                            vm.onPlayPrev();
                          },
                        ),
                        PlayButton(state: vm, size: 72.0),
                        IconButton(
                          icon: Icon(Icons.skip_next),
                          iconSize: 42.0,
                          onPressed: () {
                            vm.onPlayNext();
                          },
                        ),
                      ],
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
  final String? songTitle;

  const SongTitle({Key? key, this.songTitle}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      songTitle ?? '',
      style: TextStyle(fontSize: 18.0),
      overflow: TextOverflow.fade,
      maxLines: 1,
    );
  }
}

class ArtistTitle extends StatelessWidget {
  final String? artistName;

  const ArtistTitle({Key? key, this.artistName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      artistName ?? "",
      style: theme.textTheme.subtitle1!.copyWith(
        fontSize: 12.0,
        color: Colors.white70,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }
}

class PlayerScreen extends StatelessWidget {
  static final String routeName = "/player";

  const PlayerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      appBar: AppBarSettings(
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
  final double size;
  final Function(PositionListener) onStartListen;
  final Function(PositionListener) onStopListen;
  final Function(int) onSeek;

  UpdatingPlayerSlider({
    Key? key,
    required this.size,
    required this.onSeek,
    required this.onStartListen,
    required this.onStopListen,
  }) : super(key: key);

  @override
  State<UpdatingPlayerSlider> createState() {
    return UpdatingPlayerSliderState();
  }
}

class UpdatingPlayerSliderState extends State<UpdatingPlayerSlider>
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
    stream = StreamController<PositionUpdate>(
      onListen: () {},
      onCancel: () {
        log('UpdatingPlayerSliderState: onCancel');
        widget.onStopListen(this);
      },
    );
    log('UpdatingPlayerSliderState: onInitListen');
    widget.onStartListen(this);
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
      size: size,
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
  final double size;
  final Function(int) onChanged;

  ProgressBar({
    Key? key,
    required this.onChanged,
    required this.total,
    required this.position,
    required this.size,
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
          SizedBox(height: 10.0),
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
    Key? key,
    required this.state,
    required this.size,
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

  Icon _getIcon(PlayerStates current) {
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
