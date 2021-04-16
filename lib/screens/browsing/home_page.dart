import 'dart:math';

import 'package:async_redux/async_redux.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:subsound/components/covert_art.dart';
import 'package:subsound/screens/login/album_page.dart';
import 'package:subsound/state/appcommands.dart';
import 'package:subsound/state/appstate.dart';
import 'package:subsound/state/playerstate.dart';
import 'package:subsound/subsonic/requests/get_album.dart';
import 'package:subsound/subsonic/requests/get_album_list.dart';
import 'package:subsound/subsonic/requests/get_artist.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _HomePageViewModel>(
      converter: (st) => _HomePageViewModel(
        currentSongId: st.state.playerState.currentSong?.id ?? '',
        onPlayAlbum: (album) => st.dispatch(PlayerCommandPlayAlbum(album)),
        onPlaySong: (song, queue) => st.dispatch(PlayerCommandContextualPlay(
          songId: song.id,
          playQueue: queue,
        )),
        onLoadStarred: () async {
          final load1 = st.dispatchFuture(RefreshStarredCommand());
          final load2 = st.dispatchFuture(
              GetAlbumsCommand(type: GetAlbumListType.recent, pageSize: 20));

          await Future.wait([load1, load2]);

          final starred = st.state.dataState.stars;

          final data = [
            ...starred.albums.entries
                .map((key) => StarredItem(album: key.value))
                .toList(),
            ...starred.songs.entries
                .map((key) => StarredItem(song: key.value))
                .toList(),
          ];

          data.sort((a, b) {
            if (a.getAlbum() != null) {
              if (b.getAlbum() != null) {
                return a
                        .getAlbum()!
                        .starredAt!
                        .compareTo(b.getAlbum()!.starredAt!) *
                    -1;
              } else {
                return a
                        .getAlbum()!
                        .starredAt!
                        .compareTo(b.getSong()!.starredAt!) *
                    -1;
              }
            } else {
              if (b.getAlbum() != null) {
                return a
                        .getSong()!
                        .starredAt!
                        .compareTo(b.getAlbum()!.starredAt!) *
                    -1;
              } else {
                return a
                        .getSong()!
                        .starredAt!
                        .compareTo(b.getSong()!.starredAt!) *
                    -1;
              }
            }
          });

          return HomeData(
            data,
            st.state.dataState.albums,
          );
        },
      ),
      builder: (context, vm) => _StarredPageStateful(model: vm),
    );
  }
}

class _StarredPageStateful extends StatefulWidget {
  final _HomePageViewModel model;
  _StarredPageStateful({Key? key, required this.model}) : super(key: key);

  @override
  State<_StarredPageStateful> createState() {
    return _StarredPageState();
  }
}

class StarredSongRow extends StatelessWidget {
  final SongResult song;
  final bool isPlaying;
  final Function(SongResult) onTapRow;
  final Function(SongResult) onTapCover;

  StarredSongRow({
    Key? key,
    required this.song,
    required this.isPlaying,
    required this.onTapRow,
    required this.onTapCover,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var subtitle = song.artistName;
    if (song.albumName.isNotEmpty) {
      subtitle = subtitle + "  -  ${song.albumName}";
    }
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: homePaddingLeft),
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
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: isPlaying ? TextStyle(color: theme.accentColor) : null,
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: isPlaying ? TextStyle(color: theme.selectedRowColor) : null,
      ),
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

  bool isPlaying(String currentSongId) {
    return song?.id == currentSongId;
  }
}

class HomeData {
  final List<StarredItem> starred;
  final Albums albums;

  HomeData(this.starred, this.albums);
}

class _HomePageViewModel extends Vm {
  final String currentSongId;
  final Function(SongResult, List<SongResult>) onPlaySong;
  final Function(AlbumResultSimple) onPlayAlbum;
  final Future<HomeData> Function() onLoadStarred;

  _HomePageViewModel({
    required this.currentSongId,
    required this.onPlaySong,
    required this.onPlayAlbum,
    required this.onLoadStarred,
  }) : super(equals: [currentSongId]);
}

class StarredListView extends StatelessWidget {
  final _HomePageViewModel model;
  final HomeData data;

  const StarredListView({
    Key? key,
    required this.model,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var starred = data.starred;

    final itemCount = starred.length + 1;

    return ListView.builder(
      physics: BouncingScrollPhysics(),
      itemCount: itemCount,
      padding: EdgeInsets.zero,
      itemBuilder: (context, listIndex) {
        if (listIndex == 0) {
          return AlbumsScrollView(data: data);
        } else if (listIndex == 1) {
          return HomePageTitle("Starred");
        } else {
          final idx = listIndex - 2;
          return StarredRow(
            item: starred[idx],
            isPlaying: starred[idx].isPlaying(model.currentSongId),
            onPlay: (item) {
              if (item.getSong() != null) {
                var queue = starred
                    //.sublist(idx)
                    .where((element) => element.getSong() != null)
                    .map((e) => e.getSong()!)
                    .toList();
                model.onPlaySong(item.getSong()!, queue);
              } else if (item.getAlbum() != null) {
                model.onPlayAlbum(item.getAlbum()!);
              } else {}
            },
          );
        }
      },
    );
  }
}

class HomePageTitle extends StatelessWidget {
  final String text;
  const HomePageTitle(this.text, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(
          left: homePaddingLeft,
          bottom: homePaddingBottom,
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 24),
        ));
  }
}

const homePaddingLeft = 8.0;
const homePaddingBottom = 8.0;

class AlbumsScrollView extends StatelessWidget {
  final HomeData data;

  AlbumsScrollView({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    const albumHeight = 120.0;
    const albumPaddingTop = 8.0;
    const albumFooterHeight = 30.0;
    const containerHeight =
        albumHeight + albumPaddingTop + homePaddingBottom + albumFooterHeight;

    final totalCount = data.albums.albums.length;
    final albums =
        data.albums.albums.values.toList().sublist(0, min(10, totalCount));

    return Container(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomePageTitle(
              "Recent albums",
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: BouncingScrollPhysics(),
              child: Row(
                children: albums
                    .map((a) => Padding(
                          padding: const EdgeInsets.only(
                            left: homePaddingLeft,
                            top: albumPaddingTop,
                            right: 8.0,
                            bottom: homePaddingBottom,
                          ),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) =>
                                    AlbumScreen(albumId: a.id),
                              ));
                            },
                            child: Column(
                              children: [
                                CoverArtImage(
                                  a.coverArtLink,
                                  id: a.coverArtId,
                                  height: albumHeight,
                                  width: albumHeight,
                                ),
                                Container(
                                  width: albumHeight,
                                  // color: Colors.black,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: homePaddingBottom / 2),
                                      Text(a.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.subtitle1),
                                      SizedBox(height: homePaddingBottom / 2),
                                      Text(
                                        a.artist,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style:
                                            theme.textTheme.bodyText2!.copyWith(
                                          color: theme.textTheme.caption!.color,
                                        ),
                                      ),
                                      SizedBox(height: homePaddingBottom / 2),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
            // ListView.builder(
            //   scrollDirection: Axis.horizontal,
            //   itemCount: albums.length,
            //   itemBuilder: (context, idx) {
            //     var a = albums[idx];
            //
            //     return Container(
            //       child: CoverArtImage(
            //         a.coverArtLink,
            //         id: a.coverArtLink,
            //       ),
            //     );
            //   },
            // ),
          ],
        ),
      ),
    );
  }
}

class StarredRow extends StatelessWidget {
  final StarredItem item;
  final bool isPlaying;
  final Function(StarredItem) onPlay;

  const StarredRow({
    Key? key,
    required this.item,
    required this.isPlaying,
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
        isPlaying: isPlaying,
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
    throw StateError("unhandled item type");
  }
}

class _StarredPageState extends State<_StarredPageStateful> {
  late Future<HomeData> initialLoad;

  @override
  void initState() {
    super.initState();

    initialLoad = widget.model.onLoadStarred();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HomeData>(
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
                model: widget.model,
                data: loadedData,
              );
            }
          }
        });
  }
}
