import 'dart:io';

import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:subsound/screens/login/myscaffold.dart';
import 'package:subsound/utils/duration.dart';

class PlayerSong {
  String id;
  String artistId;
  String albumId;
  String coverArtId;
  String coverArtLink;
  Duration duration;
  Duration position;
  bool isStarred = false;
}

enum PlayerStates { stopped, playing, paused, buffering }

class PlayerState {
  final PlayerStates current;
  final PlayerSong currentSong;
  final List<PlayerSong> queue;

  PlayerState({
    this.current,
    this.currentSong,
    this.queue,
  });

  get isPlaying => current == PlayerStates.playing;

  get isPaused =>
      current == PlayerStates.paused || current == PlayerStates.buffering;

  get isStopped => current == PlayerStates.stopped;

  void pause() {}

  static initialState() => PlayerState(
        current: PlayerStates.stopped,
        currentSong: null,
        queue: [],
      );
}

class PlayerController extends StatefulWidget {
  @override
  _PlayerControllerState createState() => _PlayerControllerState();
}

class _PlayerControllerState extends State<PlayerController> {
  // AudioPlayer advancedPlayer;
  // AudioCache audioCache;
  PlayerState playerState;
  FlutterSoundPlayer myPlayer = FlutterSoundPlayer();
  bool _mPlayerIsInited = false;

  /// global key so we can pause/resume the player via the api.
  var playerStateKey = GlobalKey<SoundPlayerUIState>();

  @override
  void initState() {
    super.initState();
    myPlayer
        .openAudioSession(
      focus: AudioFocus.requestFocusAndStopOthers,
      withUI: false,
    )
        .then((value) {
      setState(() {
        // Be careful : openAudioSession return a Future.
        // Do not access your FlutterSoundPlayer or FlutterSoundRecorder before the completion of the Future
        _mPlayerIsInited = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }

  final _exampleAudioFilePathMP3 =
      'https://file-examples-com.github.io/uploads/2017/11/file_example_MP3_700KB.mp3';

  void play() async {
    await myPlayer.startPlayer(
        fromURI: _exampleAudioFilePathMP3,
        codec: Codec.mp3,
        whenFinished: () {
          setState(() {});
        });
    setState(() {});
  }

  Future<void> stopPlayer() async {
    if (myPlayer != null) {
      await myPlayer.stopPlayer();
    }
  }

  @override
  void dispose() {
    stopPlayer();
    // Be careful : you must `close` the audio session when you have finished with it.
    myPlayer.closeAudioSession();
    myPlayer = null;

    super.dispose();
  }
}

class PlayerView extends StatelessWidget {
  final PlayerState playerState;

  const PlayerView({Key key, this.playerState}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black26,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints.tightForFinite(width: 400),
          //color: Colors.tealAccent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SongTitle(playerState: playerState),
                ],
              ),
              SizedBox(height: 10.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ArtistTitle(playerState: playerState),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PlayerSlider(playerState: playerState, size: 300.0),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () {},
                    child: Icon(Icons.skip_previous, size: 42.0),
                  ),
                  PlayButton(state: playerState, size: 72.0),
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
    );
  }
}

class SongTitle extends StatelessWidget {
  final PlayerState playerState;

  const SongTitle({Key key, this.playerState}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      "Fsdafdsafdsafdsafdsafdsafdssa",
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
      "Bklbjxcjblkvcxjblkvcxjkl",
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
      // position: position,
      // total: total,
      onChanged: (nextValue) {},
      position: Duration(seconds: 100),
      total: Duration(seconds: 279),
      size: size,
    );
  }

  static Duration _getMax(PlayerState playerState) {
    if (playerState == null || playerState.currentSong == null) {
      return Duration();
    }
    return playerState.currentSong.duration;
  }

  static Duration _getPosition(PlayerState playerState) {
    if (playerState == null || playerState.currentSong == null) {
      return Duration();
    }
    return playerState.currentSong.position;
  }

  static double _getProgressValue(PlayerState playerState) {
    if (playerState == null || playerState.currentSong == null) {
      return 0.9;
    }
    var duration = playerState.currentSong.duration.inMilliseconds.toDouble();
    if (duration == 0.0) {
      duration = 1.0;
    }
    return playerState.currentSong.position.inMilliseconds.toDouble() /
        duration;
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
            min: 0,
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

class MiniPlayer extends StatelessWidget {
  final double size;

  const MiniPlayer({Key key, this.size}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // color: Colors.black54.withOpacity(0.3),
      child: SizedBox(
        height: size ?? 50.0,
        child: ListTile(
          leading: Icon(
            Icons.album,
            color: Colors.white,
          ),
          title: InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => PlayerView(),
                enableDrag: true,
                isDismissible: false,
              );
            },
            child: Text("Nothing playing..."),
          ),
          trailing: InkWell(
            onTap: () {},
            child: Icon(
              Icons.play_circle_fill,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
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

class PlayerProvider extends StatefulWidget {
  @override
  _PlayerProviderState createState() => _PlayerProviderState();
}

class _PlayerProviderState extends State<PlayerProvider> {
  AudioPlayer _player = AudioPlayer();
  AudioCache _audioCache = AudioCache();
  final WidgetBuilder builder;

  _PlayerProviderState({
    this.builder,
  });

  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      // Calls to Platform.isIOS fails on web
      return;
    }
    if (Platform.isIOS) {
      if (_audioCache.fixedPlayer != null) {
        _audioCache.fixedPlayer.startHeadlessService();
      }
      _player.startHeadlessService();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Builder(builder: builder);
  }
}
