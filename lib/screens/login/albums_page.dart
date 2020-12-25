import 'package:flutter/material.dart';
import 'package:subsound/subsonic/context.dart';
import 'package:subsound/subsonic/models/album.dart';
import 'package:subsound/subsonic/requests/get_album_list.dart';
import 'package:subsound/subsonic/requests/get_album_list2.dart';

class AlbumsPage extends StatefulWidget {
  final SubsonicContext ctx;

  const AlbumsPage({Key key, this.ctx}) : super(key: key);

  @override
  State<AlbumsPage> createState() {
    return AlbumsPageState(ctx);
  }
}

class AlbumRow extends StatelessWidget {
  final Album album;

  const AlbumRow({Key key, this.album}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Image.network(album.coverArtLink,
            scale: 1.0, width: 48.0, height: 48.0),
        Text(album.artist),
        Text(" - "),
        Text(album.title),
      ],
    );
  }
}

class AlbumsPageState extends State<AlbumsPage> {
  final SubsonicContext ctx;

  AlbumsPageState(this.ctx);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: FutureBuilder<List<Album>>(
            future: load(),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return CircularProgressIndicator();
              } else {
                if (snapshot.hasError) {
                  return Text("${snapshot.error}");
                } else {
                  return ListView(
                    children:
                        snapshot.data.map((a) => AlbumRow(album: a)).toList(),
                  );
                }
              }
            }));
  }

  Future<List<Album>> load() {
    return GetAlbumList2(type: GetAlbumListType.alphabeticalByArtist)
        .run(ctx)
        .then((value) => value.data);
  }
}
