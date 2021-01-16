import 'package:flutter/material.dart';
import 'package:subsound/components/covert_art.dart';
import 'package:subsound/screens/login/album_page.dart';
import 'package:subsound/subsonic/context.dart';
import 'package:subsound/subsonic/requests/get_album.dart';
import 'package:subsound/subsonic/requests/get_artist.dart';
import 'package:subsound/subsonic/requests/get_starred2.dart';

class StarredPage extends StatefulWidget {
  final SubsonicContext ctx;

  const StarredPage({Key key, this.ctx}) : super(key: key);

  @override
  State<StarredPage> createState() {
    return StarredPageState(ctx);
  }
}

class StarredSongRow extends StatelessWidget {
  final SongResult songResult;
  final Function(SongResult) onTap;

  const StarredSongRow({
    Key key,
    @required this.songResult,
    @required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        this.onTap(songResult);
      },
      leading: CoverArtImage(
        songResult.coverArtLink,
        id: songResult.coverArtId,
        width: 48.0,
        height: 48.0,
      ),
      title: Text(songResult.title),
      subtitle: Text(songResult.artistName),
    );
  }
}

class StarredAlbumRow extends StatelessWidget {
  final AlbumResultSimple album;
  final Function(AlbumResultSimple) onTap;

  const StarredAlbumRow({
    Key key,
    @required this.album,
    @required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        this.onTap(album);
      },
      leading: CoverArtImage(
        album.coverArtLink,
        id: album.coverArtId,
        width: 48.0,
        height: 48.0,
      ),
      title: Text(album.title),
      subtitle: Text(album.artistName),
    );
  }
}

class StarredListView extends StatelessWidget {
  final SubsonicContext ctx;
  final GetStarred2Result data;

  const StarredListView({
    Key key,
    this.ctx,
    this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //final itemCount = data.albums.length + data.songs.length;
    // final itemCount = data.songs.length;
    final itemCount = data.albums.length;
    return ListView.builder(
        physics: BouncingScrollPhysics(),
        itemCount: itemCount,
        // itemBuilder: (context, idx) => StarredSongRow(
        //       songResult: data.songs[idx],
        //       onTap: (SongResult song) {
        //         Navigator.of(context).push(MaterialPageRoute(
        //           builder: (context) => AlbumScreen(
        //             albumId: song.albumId,
        //           ),
        //         ));
        //       },
        //     ));
        itemBuilder: (context, idx) => StarredAlbumRow(
              album: data.albums[idx],
              onTap: (AlbumResultSimple album) {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => AlbumScreen(
                    albumId: album.id,
                  ),
                ));
              },
            ));
  }
}

class StarredPageState extends State<StarredPage> {
  final SubsonicContext ctx;
  GetStarred2Result _data;
  Future<GetStarred2Result> initialLoad;

  StarredPageState(this.ctx);

  @override
  void initState() {
    super.initState();
    initialLoad = load().then((value) {
      setState(() {
        _data = value;
      });
      return value;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: FutureBuilder<GetStarred2Result>(
            future: initialLoad,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return CircularProgressIndicator();
              } else {
                if (snapshot.hasError) {
                  return Text("${snapshot.error}");
                } else {
                  _data = snapshot.data;
                  return StarredListView(
                    ctx: ctx,
                    data: _data,
                  );
                }
              }
            }));
  }

  Future<GetStarred2Result> load() {
    return GetStarred2().run(ctx).then((value) => value.data);
  }
}
