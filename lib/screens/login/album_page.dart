import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:subsound/components/covert_art.dart';
import 'package:subsound/screens/login/loginscreen.dart';
import 'package:subsound/subsonic/context.dart';
import 'package:subsound/subsonic/requests/get_album.dart';

import 'myscaffold.dart';

const WilderunAlbumID = '5015da3a81d22b33a3d7448ba508b1dd';

class WilderunAlbumScreen extends StatelessWidget {
  static final routeName = "/album/wilderun";
  final ServerData serverData;
  final SubsonicContext client;

  WilderunAlbumScreen({
    @required this.serverData,
  }) : client = SubsonicContext(
          serverId: serverData.uri,
          name: "",
          endpoint: Uri.tryParse(serverData.uri),
          user: serverData.username,
          pass: serverData.password,
        );

  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      appBar: null,
      disableAppBar: true,
      body: Center(
        child: AlbumPage(
          ctx: client,
          albumId: WilderunAlbumID,
        ),
      ),
    );
  }
}

class AlbumScreen extends StatelessWidget {
  final SubsonicContext client;
  final String albumId;

  AlbumScreen({
    @required ServerData serverData,
    @required this.albumId,
  }) : client = SubsonicContext(
          serverId: serverData.uri,
          name: "",
          endpoint: Uri.tryParse(serverData.uri),
          user: serverData.username,
          pass: serverData.password,
        );

  AlbumScreen.client({
    @required this.client,
    @required this.albumId,
  });

  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      appBar: null,
      disableAppBar: true,
      body: Center(
        child: AlbumPage(
          ctx: client,
          albumId: albumId,
        ),
      ),
    );
  }
}

class AlbumPage extends StatefulWidget {
  final SubsonicContext ctx;
  final String albumId;

  const AlbumPage({Key key, this.ctx, this.albumId}) : super(key: key);

  @override
  State<AlbumPage> createState() {
    return AlbumPageState(ctx: ctx, albumId: albumId);
  }
}

class SongRow extends StatelessWidget {
  final SongResult song;

  const SongRow({Key key, this.song}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        children: [
          Text("${song.trackNumber}"),
          Flexible(
            child: Container(
              child: Column(
                children: [
                  Text(
                    song.title,
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
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
      margin: EdgeInsets.all(10.0),
    );
  }
}

class AlbumView extends StatelessWidget {
  final AlbumResult album;

  const AlbumView({Key key, this.album}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // var expandedHeight = MediaQuery.of(context).size.height / 3;
    var expandedHeight = 350.0;
    return Container(
      color: Colors.black54,
      child: CustomScrollView(
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
                  CoverArtImage(
                    album.coverArtLink,
                    id: album.coverArtId,
                    height: expandedHeight * 1.6,
                    width: expandedHeight * 1.6,
                    fit: BoxFit.cover,
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
          SliverList(
              delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
              return SongRow(song: album.songs[index]);
            },
            childCount: album.songs.length,
          )),
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

  AlbumPageState({this.ctx, this.albumId});

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
                return AlbumView(album: snapshot.data);
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
