import 'dart:developer';

import 'package:async_redux/async_redux.dart';
import 'package:flutter/material.dart';
import 'package:subsound/components/covert_art.dart';
import 'package:subsound/screens/login/artist_page.dart';
import 'package:subsound/state/appcommands.dart';
import 'package:subsound/state/appstate.dart';
import 'package:subsound/state/playerstate.dart';
import 'package:subsound/subsonic/context.dart';
import 'package:subsound/subsonic/requests/get_album.dart';

import 'myscaffold.dart';

class _AlbumViewModelFactory extends VmFactory<AppState, AlbumScreen> {
  _AlbumViewModelFactory(widget) : super(widget);

  @override
  AlbumViewModel fromStore() {
    return AlbumViewModel(
      serverData: state.loginState,
      currentSongId: state.playerState.currentSong?.id,
      loadAlbum: (String albumId) {
        return dispatchFuture(GetAlbumCommand(albumId: albumId))
            .then((value) => this.currentState().dataState.albums.get(albumId));
      },
      onPlay: (String songId, AlbumResult album) {
        dispatch(PlayerCommandPlaySongInAlbum(songId: songId, album: album));
      },
    );
  }
}

class AlbumViewModel extends Vm {
  final ServerData serverData;
  final String? currentSongId;
  final Future<AlbumResult?> Function(String albumId) loadAlbum;
  final Function(String songId, AlbumResult album) onPlay;

  AlbumViewModel({
    required this.serverData,
    required this.currentSongId,
    required this.loadAlbum,
    required this.onPlay,
  }) : super(equals: [
          serverData,
          currentSongId ?? '',
        ]);
}

class AlbumScreen extends StatelessWidget {
  final String albumId;

  AlbumScreen({
    required this.albumId,
  });

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, AlbumViewModel>(
      vm: () => _AlbumViewModelFactory(this),
      builder: (context, state) => MyScaffold(
        appBar: AppBarSettings(disableAppBar: true),
        body: (context) => Center(
          child: AlbumPage(
            ctx: state.serverData.toClient(),
            currentSongId: state.currentSongId,
            albumId: albumId,
            loadAlbum: state.loadAlbum,
            onPlay: state.onPlay,
          ),
        ),
      ),
    );
  }
}

class AlbumPage extends StatefulWidget {
  final SubsonicContext ctx;
  final String albumId;
  final String? currentSongId;
  final Future<AlbumResult?> Function(String albumId) loadAlbum;
  final Function(String songId, AlbumResult album) onPlay;

  const AlbumPage({
    Key? key,
    required this.ctx,
    required this.albumId,
    required this.currentSongId,
    required this.onPlay,
    required this.loadAlbum,
  }) : super(key: key);

  @override
  State<AlbumPage> createState() {
    return AlbumPageState();
  }
}

class SongRow extends StatelessWidget {
  final SongResult song;
  final bool isPlaying;
  final Function(SongResult) onPlay;

  const SongRow({
    Key? key,
    required this.song,
    required this.isPlaying,
    required this.onPlay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Container(
      child: InkWell(
        onTap: () {
          this.onPlay(this.song);
        },
        child: Row(
          children: [
            Text(
              "${song.trackNumber}",
              style: TextStyle(
                color: isPlaying
                    ? theme.accentColor
                    : theme.colorScheme.onPrimary.withOpacity(0.7),
              ),
            ),
            Flexible(
              child: Container(
                child: Column(
                  children: [
                    Text(
                      song.title,
                      style: TextStyle(
                        color: isPlaying
                            ? theme.accentColor
                            : theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        //fontSize: 16.0,
                      ),
                      textAlign: TextAlign.left,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                margin: EdgeInsets.all(10.0),
              ),
            ),
          ],
        ),
      ),
      margin: EdgeInsets.all(10.0),
    );
  }
}

class AlbumView extends StatelessWidget {
  final AlbumResult album;
  final String? currentSongId;
  final Function(String songId, AlbumResult album) onPlay;

  const AlbumView({
    Key? key,
    required this.album,
    required this.currentSongId,
    required this.onPlay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // var expandedHeight = MediaQuery.of(context).size.height / 3;
    var expandedHeight = 350.0;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.8],
          colors: [
            Colors.blueGrey.withOpacity(0.7),
            Colors.black.withOpacity(0.7),
          ],
        ),
      ),
      //color: Colors.black54,
      child: CustomScrollView(
        primary: true,
        physics: const BouncingScrollPhysics(),
        slivers: <Widget>[
          SliverAppBar(
            backgroundColor: Colors.black54,
            // foregroundColor: Colors.black54,
            // shadowColor: Colors.black54,
            expandedHeight: expandedHeight,
            stretch: true,
            centerTitle: false,
            snap: false,
            floating: true,
            pinned: true,
            primary: true,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              //titlePadding: EdgeInsets.only(left: 5.0, bottom: 10.0),
              title: Text(
                album.name,
                //textAlign: TextAlign.start,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
                //overflow: TextOverflow.ellipsis,
                //maxLines: 1,
              ),
              collapseMode: CollapseMode.parallax,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints.tightFor(width: 450.0),
                    child: Hero(
                      tag: album.coverArtId,
                      child: CoverArtImage(
                        album.coverArtLink,
                        id: album.coverArtId,
                        height: expandedHeight * 1.6,
                        width: expandedHeight * 1.6,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        // end: Alignment(0.0, 0.0),
                        begin: Alignment.bottomCenter,
                        end: Alignment(0.0, 0.0),
                        colors: <Color>[
                          Color(0x60000000),
                          Color(0x00000000),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              stretchModes: [
                StretchMode.fadeTitle,
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              height: 60,
              padding: EdgeInsets.only(left: 20, top: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              ArtistScreen(artistId: album.artistId),
                        ),
                      );
                    },
                    child: Text(
                      album.artistName,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    "${album.year}",
                    style: TextStyle(
                        fontWeight: FontWeight.normal,
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimary
                            .withOpacity(0.7)),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final song = album.songs[index];
                final isPlaying =
                    currentSongId != null && currentSongId == song.id;
                return SongRow(
                  isPlaying: isPlaying,
                  song: song,
                  onPlay: (song) {
                    this.onPlay(song.id, this.album);
                  },
                );
              },
              childCount: album.songs.length,
            ),
          ),
        ],
      ),
    );
  }
}

class AlbumPageState extends State<AlbumPage> {
  late Future<AlbumResult> future;

  AlbumPageState();

  @override
  void initState() {
    super.initState();
    this.future = load(widget.albumId);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // color: Colors.black54,
      child: FutureBuilder<AlbumResult>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasData) {
                return AlbumView(
                  currentSongId: widget.currentSongId,
                  album: snapshot.data!,
                  onPlay: widget.onPlay,
                );
              } else {
                return Center(child: Text("${snapshot.error}"));
              }
            } else {
              return Center(child: CircularProgressIndicator());
            }
          }),
    );
  }

  Future<AlbumResult> load(String albumId) {
    return widget.loadAlbum(albumId).then((value) => value!).catchError((err) {
      log('GetAlbum:error:$albumId', error: err);
      return Future<AlbumResult>.error(err);
    });
  }
}
