import 'package:async_redux/async_redux.dart';
import 'package:flutter/material.dart';
import 'package:subsound/components/covert_art.dart';
import 'package:subsound/screens/login/album_page.dart';
import 'package:subsound/state/appcommands.dart';
import 'package:subsound/state/appstate.dart';
import 'package:subsound/subsonic/requests/requests.dart';

import 'myscaffold.dart';

class ArtistScreen extends StatelessWidget {
  final String artistId;

  ArtistScreen({
    required this.artistId,
  });

  ArtistScreen.of(this.artistId);

  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      appBar: AppBarSettings(
        disableAppBar: true,
      ),
      body: (context) => Center(
        child: ArtistPage(
          artistId: artistId,
        ),
      ),
    );
  }
}

class ArtistPageModel extends Vm {
  final Future<ArtistResult?> Function(String artistId) onLoad;

  ArtistPageModel({
    required this.onLoad,
  }) : super(equals: []);
}

class ArtistPage extends StatelessWidget {
  final String artistId;

  const ArtistPage({
    Key? key,
    required this.artistId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, ArtistPageModel>(
      vm: () => ArtistPageModelFactory(this),
      builder: (context, vm) => _ArtistPageStateful(
        artistId: artistId,
        vm: vm,
      ),
    );
  }
}

class ArtistPageModelFactory extends VmFactory<AppState, ArtistPage, ArtistPageModel> {
  ArtistPageModelFactory(ArtistPage widget) : super(widget);
  @override
  ArtistPageModel fromStore() {
    return ArtistPageModel(
      onLoad: (artistId) => dispatchAsync(GetArtistCommand(artistId: artistId))
          .then((value) => currentState().dataState.artists.get(artistId)),
    );
  }
}

class _ArtistPageStateful extends StatefulWidget {
  final String artistId;
  final ArtistPageModel vm;

  _ArtistPageStateful({
    Key? key,
    required this.artistId,
    required this.vm,
  }) : super(key: key);

  @override
  State<_ArtistPageStateful> createState() {
    return _ArtistPageState();
  }
}

class AlbumRow extends StatelessWidget {
  final AlbumResultSimple album;
  final Function(AlbumResultSimple) onSelectedAlbum;

  const AlbumRow({
    Key? key,
    required this.album,
    required this.onSelectedAlbum,
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
              id: album.coverArtId,
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
  final Function(AlbumResultSimple) onSelectedAlbum;

  const ArtistView(
      {Key? key, required this.artist, required this.onSelectedAlbum})
      : super(key: key);

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
      child: CustomScrollView(
        primary: true,
        physics: BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: <Widget>[
          SliverAppBar(
            backgroundColor: Colors.black54,
            expandedHeight: expandedHeight,
            stretch: true,
            centerTitle: false,
            snap: false,
            floating: false,
            pinned: true,
            primary: true,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              //titlePadding: EdgeInsets.only(left: 5.0, bottom: 10.0),
              title: Text(
                artist.name,
                //textAlign: TextAlign.start,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.0,
                ),
              ),
              collapseMode: CollapseMode.parallax,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints.tightFor(width: 450.0),
                    child: CoverArtImage(
                      artist.coverArtLink,
                      id: artist.coverArtId,
                      height: expandedHeight * 1.6,
                      width: expandedHeight * 1.6,
                      fit: BoxFit.cover,
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
                //StretchMode.blurBackground,
              ],
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate(artist
                .albums
                .map((album) =>
                    AlbumRow(album: album, onSelectedAlbum: onSelectedAlbum))
                .toList()),
          ),
        ],
      ),
    );
  }
}

class AlbumList extends StatelessWidget {
  final ArtistResult artist;
  final List<AlbumResultSimple> albums;
  final Function(AlbumResultSimple) onSelectedAlbum;

  const AlbumList({
    Key? key,
    required this.artist,
    required this.albums,
    required this.onSelectedAlbum,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView(
        children: albums
            .map((a) => AlbumRow(
                  album: a,
                  onSelectedAlbum: onSelectedAlbum,
                ))
            .toList(),
      ),
    );
  }
}

class _ArtistPageState extends State<_ArtistPageStateful> {
  late Future<ArtistResult> loader;

  _ArtistPageState();

  @override
  void initState() {
    super.initState();
    loader = load(widget.artistId);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: FutureBuilder<ArtistResult>(
            future: loader,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return CircularProgressIndicator();
              } else {
                if (snapshot.hasData) {
                  return ArtistView(
                    artist: snapshot.data!,
                    onSelectedAlbum: (album) {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => AlbumScreen(
                                albumId: album.id,
                              )));
                    },
                  );
                } else {
                  return Text("${snapshot.error}");
                }
              }
            }));
  }

  Future<ArtistResult> load(String artistId) {
    return widget.vm.onLoad(artistId).then((value) => value!);
  }
}
