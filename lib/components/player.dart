import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_sound/flutter_sound.dart';

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
  PlayerStates current;
  PlayerSong currentSong;
  List<PlayerSong> queue;

  get isPlaying => current == PlayerStates.playing;

  get isPaused =>
      current == PlayerStates.paused || current == PlayerStates.buffering;

  get isStopped => current == PlayerStates.stopped;

  void pause() {}
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

class PlayerScreen extends StatelessWidget {
  static final String routeName = "/player";
  final PlayerState playerState;

  const PlayerScreen({Key key, this.playerState}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            //color: Colors.tealAccent,
            child: Text(
              "This is the player!",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          )
        ],
      ),
    );
  }
}

class MiniPlayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: SizedBox(
        height: 50.0,
        child: ListTile(
          leading: Icon(
            Icons.album,
            color: Colors.white,
          ),
          title: InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => PlayerScreen(),
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
  @override
  Widget build(BuildContext context) {
    return MiniPlayer();
  }
}
