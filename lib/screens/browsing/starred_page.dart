import 'package:async_redux/async_redux.dart';
import 'package:flutter/material.dart';
import 'package:subsound/components/covert_art.dart';
import 'package:subsound/components/player.dart';
import 'package:subsound/screens/login/album_page.dart';
import 'package:subsound/state/appstate.dart';
import 'package:subsound/state/playerstate.dart';
import 'package:subsound/subsonic/context.dart';
import 'package:subsound/subsonic/requests/get_album.dart';
import 'package:subsound/subsonic/requests/get_artist.dart';
import 'package:subsound/subsonic/requests/get_starred2.dart';

class StarredPage extends StatefulWidget {
  final SubsonicContext ctx;

  const StarredPage({Key? key, required this.ctx}) : super(key: key);

  @override
  State<StarredPage> createState() {
    return StarredPageState(ctx);
  }
}

class StarredSongRow extends StatelessWidget {
  final SongResult song;
  final Function(SongResult) onTapRow;
  final Function(SongResult) onTapCover;

  const StarredSongRow({
    Key? key,
    required this.song,
    required this.onTapRow,
    required this.onTapCover,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      onTap: () {
        this.onTapRow(song);
      },
      leading: GestureDetector(
        onTap: () {
          this.onTapCover(song);
        },
        child: CoverArtImage(
          song.coverArtLink,
          id: song.coverArtId,
          width: 48.0,
          height: 48.0,
        ),
      ),
      title: Text(song.title),
      subtitle: Text(song.artistName),
    );
  }
}

class StarredAlbumRow extends StatelessWidget {
  final AlbumResultSimple album;
  final Function(AlbumResultSimple) onTap;
  final Function(AlbumResultSimple) onTapCover;

  const StarredAlbumRow({
    Key? key,
    required this.album,
    required this.onTap,
    required this.onTapCover,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // return Container(
    //   height: 100.0,
    //   child: Text(album.name),
    // );
    return ListTile(
      onTap: () {
        this.onTap(album);
      },
      leading: CoverArtImage(
        album.coverArtLink,
        id: album.coverArtId,
        width: 72.0,
        height: 72.0,
      ),
      title: Text(album.title),
      subtitle: Text(album.artistName),
    );
  }
}

class StarredItem {
  final SongResult? song;
  final AlbumResultSimple? album;

  StarredItem({this.song, this.album});

  SongResult? getSong() {
    return song;
  }

  AlbumResultSimple? getAlbum() {
    return album;
  }
}

class StarredViewModel {
  final Function(SongResult) onPlaySong;
  final Function(AlbumResultSimple) onPlayAlbum;

  StarredViewModel({required this.onPlaySong, required this.onPlayAlbum});
}

class StarredListView extends StatelessWidget {
  final SubsonicContext ctx;
  final List<StarredItem> data;

  const StarredListView({
    Key? key,
    required this.ctx,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //final itemCount = data.albums.length + data.songs.length;
    // final itemCount = data.songs.length;
    final itemCount = data.length;
    return StoreConnector<AppState, StarredViewModel>(
      converter: (st) => StarredViewModel(
        onPlayAlbum: (album) => st.dispatch(PlayerCommandPlayAlbum(album)),
        onPlaySong: (song) => st.dispatch(PlayerCommandPlaySong(
          PlayerSong.from(song),
        )),
      ),
      builder: (context, model) => ListView.builder(
        physics: BouncingScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, idx) => StarredRow(
          onPlay: (item) {
            if (item.getSong() != null) {
              model.onPlaySong(item.getSong()!);
            } else if (item.getAlbum() != null) {
              model.onPlayAlbum(item.getAlbum()!);
            } else {}
          },
          item: data[idx],
        ),
      ),
    );
  }
}

class StarredRow extends StatelessWidget {
  final StarredItem item;
  final Function(StarredItem) onPlay;

  const StarredRow({
    Key? key,
    required this.item,
    required this.onPlay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (item.getAlbum() != null) {
      return StarredAlbumRow(
        album: item.getAlbum()!,
        onTap: (AlbumResultSimple album) {
          this.onPlay(item);
        },
        onTapCover: (album) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => AlbumScreen(
              albumId: album.id,
            ),
          ));
        },
      );
    }
    if (item.getSong() != null) {
      return StarredSongRow(
        song: item.getSong()!,
        onTapCover: (SongResult song) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => AlbumScreen(
              albumId: song.albumId,
            ),
          ));
        },
        onTapRow: (SongResult song) {
          this.onPlay(item);
        },
      );
    }
    throw new StateError("unhandled item type");
  }
}

class StarredPageState extends State<StarredPage> {
  final SubsonicContext ctx;
  late Future<GetStarred2Result> initialLoad;

  StarredPageState(this.ctx);

  @override
  void initState() {
    super.initState();
    initialLoad = load().then((value) {
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
                  final loadedData = snapshot.data!;
                  return StarredListView(
                    ctx: ctx,
                    data: [
                      ...loadedData.albums
                          .map((album) => StarredItem(album: album))
                          .toList(),
                      ...loadedData.songs
                          .map((e) => StarredItem(song: e))
                          .toList(),
                    ]..sort((a, b) {
                        if (a.getAlbum() != null) {
                          if (b.getAlbum() != null) {
                            return a
                                    .getAlbum()!
                                    .createdAt
                                    .compareTo(b.getAlbum()!.createdAt) *
                                -1;
                          } else {
                            return a
                                    .getAlbum()!
                                    .createdAt
                                    .compareTo(b.getSong()!.createdAt) *
                                -1;
                          }
                        } else {
                          if (b.getAlbum() != null) {
                            return a
                                    .getSong()!
                                    .createdAt
                                    .compareTo(b.getAlbum()!.createdAt) *
                                -1;
                          } else {
                            return a
                                    .getSong()!
                                    .createdAt
                                    .compareTo(b.getSong()!.createdAt) *
                                -1;
                          }
                        }
                      }),
                  );
                }
              }
            }));
  }

  Future<GetStarred2Result> load() {
    return GetStarred2().run(ctx).then((value) => value.data);
  }
}
