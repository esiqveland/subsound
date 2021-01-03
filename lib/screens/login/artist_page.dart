import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:subsound/components/covert_art.dart';
import 'package:subsound/screens/login/album_page.dart';
import 'package:subsound/state/appstate.dart';
import 'package:subsound/subsonic/context.dart';
import 'package:subsound/subsonic/requests/requests.dart';

import 'myscaffold.dart';

class ArtistScreen extends StatelessWidget {
  final ServerData serverData;
  final SubsonicContext client;
  final String artistId;

  ArtistScreen({
    @required this.artistId,
    @required this.serverData,
  }) : client = serverData.toClient();

  ArtistScreen.of(
    this.artistId, {
    @required this.client,
    this.serverData,
  });

  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      body: (context) => Center(
        child: ArtistPage(
          ctx: client,
          artistId: this.artistId,
        ),
      ),
    );
  }
}

class ArtistPage extends StatefulWidget {
  final SubsonicContext ctx;
  final String artistId;

  const ArtistPage({Key key, this.ctx, this.artistId}) : super(key: key);

  @override
  State<ArtistPage> createState() {
    return ArtistPageState(ctx, artistId);
  }
}

class AlbumRow extends StatelessWidget {
  final AlbumResult album;
  final Function(AlbumResult) onSelectedAlbum;

  const AlbumRow({
    Key key,
    @required this.album,
    @required this.onSelectedAlbum,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onSelectedAlbum(album);
      },
      child: Container(
        margin: EdgeInsets.all(10.0),
        child: Row(
          children: [
            CoverArtImage(
              album.coverArtLink,
              width: 72.0,
              height: 72.0,
            ),
            Flexible(
              child: Container(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      album.title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16.0),
                      textAlign: TextAlign.left,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      '${album.year}',
                      style: TextStyle(
                          fontWeight: FontWeight.w100, fontSize: 12.0),
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
                margin: EdgeInsets.all(10.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ArtistView extends StatelessWidget {
  final ArtistResult artist;
  final Function(AlbumResult) onSelectedAlbum;

  const ArtistView({Key key, this.artist, this.onSelectedAlbum})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
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
      child: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Container(
              margin: EdgeInsets.only(bottom: 10.0),
              child: CoverArtImage(
                artist.coverArtLink,
                height: 250.0,
                width: 250.0,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              margin: EdgeInsets.only(
                bottom: 10.0,
                left: 10.0,
              ),
              child: Text(
                artist.name,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24.0),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              this
                  .artist
                  .albums
                  .map((album) =>
                      AlbumRow(album: album, onSelectedAlbum: onSelectedAlbum))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class AlbumList extends StatelessWidget {
  final ArtistResult artist;
  final List<AlbumResult> albums;
  final Function(AlbumResult) onSelectedAlbum;

  const AlbumList({
    Key key,
    this.artist,
    this.albums,
    this.onSelectedAlbum,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView(
        children: this
            .albums
            .map((a) => AlbumRow(
                  album: a,
                  onSelectedAlbum: onSelectedAlbum,
                ))
            .toList(),
      ),
    );
  }
}

class ArtistPageState extends State<ArtistPage> {
  final SubsonicContext ctx;
  final String artistId;

  ArtistPageState(this.ctx, this.artistId);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: FutureBuilder<ArtistResult>(
            future: load(this.artistId),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return CircularProgressIndicator();
              } else {
                if (snapshot.hasError) {
                  return Text("${snapshot.error}");
                } else {
                  return ArtistView(
                    artist: snapshot.data,
                    onSelectedAlbum: (album) {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => AlbumScreen(
                                albumId: album.id,
                              )));
                    },
                  );
                }
              }
            }));
  }

  Future<ArtistResult> load(String artistId) {
    return GetArtist(artistId)
        .run(ctx)
        .then((value) => value.data)
        .catchError((err) {
      log('GetArtist:error:$artistId', error: err);
      return Future.error(err);
    });
  }
}
