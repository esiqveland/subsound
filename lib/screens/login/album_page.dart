import 'dart:developer';

import 'package:async_redux/async_redux.dart';
import 'package:flutter/material.dart';
import 'package:subsound/components/covert_art.dart';
import 'package:subsound/components/player.dart';
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
      onPlay: (SongResult r) {
        dispatch(PlayerCommandPlaySong(PlayerSong.from(r)));
      },
    );
  }
}

class AlbumViewModel extends Vm {
  final ServerData serverData;
  final Function(SongResult) onPlay;

  AlbumViewModel({
    this.serverData,
    this.onPlay,
  }) : super(equals: [serverData]);
}

class AlbumScreen extends StatelessWidget {
  final String albumId;

  AlbumScreen({
    @required this.albumId,
  });

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, AlbumViewModel>(
      vm: _AlbumViewModelFactory(this),
      builder: (context, state) => MyScaffold(
        appBar: null,
        disableAppBar: true,
        body: (context) => Center(
          child: AlbumPage(
            ctx: state.serverData.toClient(),
            albumId: albumId,
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
  final Function(SongResult) onPlay;

  const AlbumPage({
    Key key,
    this.ctx,
    this.albumId,
    this.onPlay,
  }) : super(key: key);

  @override
  State<AlbumPage> createState() {
    return AlbumPageState(
      ctx: ctx,
      albumId: albumId,
      onPlay: onPlay,
    );
  }
}

class SongRow extends StatelessWidget {
  final SongResult song;
  final Function(SongResult) onPlay;

  const SongRow({
    Key key,
    @required this.song,
    @required this.onPlay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: InkWell(
        onTap: () {
          this.onPlay(this.song);
        },
        child: Row(
          children: [
            Text("${song.trackNumber}"),
            Flexible(
              child: Container(
                child: Column(
                  children: [
                    Text(
                      song.title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16.0),
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
  final Function(SongResult) onPlay;

  const AlbumView({
    Key key,
    @required this.album,
    @required this.onPlay,
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
          Container(
            child: SliverList(
                delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return SongRow(
                  song: album.songs[index],
                  onPlay: this.onPlay,
                );
              },
              childCount: album.songs.length,
            )),
          ),
          // Expanded(
          //   child: AlbumList(
          //     album: album,
          //     songs: album.songs,
          //   ),
          // ),
        ],
      ),
    );
  }
}

class AlbumList extends StatelessWidget {
  final AlbumResult album;
  final List<SongResult> songs;

  const AlbumList({Key key, this.album, this.songs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: this.songs.map((s) => SongRow(song: s)).toList(),
    );
  }
}

class AlbumPageState extends State<AlbumPage> {
  final SubsonicContext ctx;
  final String albumId;
  final Function(SongResult) onPlay;

  AlbumPageState({this.ctx, this.albumId, this.onPlay});

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: FutureBuilder<AlbumResult>(
          future: load(this.albumId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasError) {
                return Center(child: Text("${snapshot.error}"));
              } else {
                return AlbumView(
                  album: snapshot.data,
                  onPlay: this.onPlay,
                );
              }
            } else {
              return Center(child: CircularProgressIndicator());
            }
          }),
    );
  }

  Future<AlbumResult> load(String albumId) {
    return GetAlbum(albumId)
        .run(ctx)
        .then((value) => value.data)
        .catchError((err) {
      log('GetArtist:error:$albumId', error: err);
      return Future.error(err);
    });
  }
}
