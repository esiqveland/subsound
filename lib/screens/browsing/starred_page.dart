import 'package:async_redux/async_redux.dart';
import 'package:flutter/material.dart';
import 'package:subsound/components/covert_art.dart';
import 'package:subsound/screens/login/album_page.dart';
import 'package:subsound/state/appcommands.dart';
import 'package:subsound/state/appstate.dart';
import 'package:subsound/state/playerstate.dart';
import 'package:subsound/subsonic/requests/get_album.dart';
import 'package:subsound/subsonic/requests/get_artist.dart';

class StarredPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, StarredViewModel>(
      converter: (st) => StarredViewModel(
        currentSongId: st.state.playerState.currentSong?.id ?? '',
        onPlayAlbum: (album) => st.dispatch(PlayerCommandPlayAlbum(album)),
        onPlaySong: (song, queue) => st.dispatch(PlayerCommandContextualPlay(
          songId: song.id,
          playQueue: queue,
        )),
        onLoadStarred: (bool forceRefresh) => st
            .dispatchFuture(RefreshStarredCommand())
            .then((value) => st.state.dataState.stars),
      ),
      builder: (context, vm) => _StarredPageStateful(model: vm),
    );
  }
}

class _StarredPageStateful extends StatefulWidget {
  final StarredViewModel model;
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

class StarredViewModel extends Vm {
  final String currentSongId;
  final Function(SongResult, List<SongResult>) onPlaySong;
  final Function(AlbumResultSimple) onPlayAlbum;
  final Future<Starred> Function(bool forceRefresh) onLoadStarred;

  StarredViewModel({
    required this.currentSongId,
    required this.onPlaySong,
    required this.onPlayAlbum,
    required this.onLoadStarred,
  }) : super(equals: [currentSongId]);
}

class StarredListView extends StatelessWidget {
  final StarredViewModel model;
  final List<StarredItem> data;

  const StarredListView({
    Key? key,
    required this.model,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final itemCount = data.length;
    return ListView.builder(
      physics: BouncingScrollPhysics(),
      itemCount: itemCount,
      padding: EdgeInsets.zero,
      itemBuilder: (context, idx) => StarredRow(
        item: data[idx],
        isPlaying: data[idx].isPlaying(model.currentSongId),
        onPlay: (item) {
          if (item.getSong() != null) {
            var queue = data
                //.sublist(idx)
                .where((element) => element.getSong() != null)
                .map((e) => e.getSong()!)
                .toList();
            model.onPlaySong(item.getSong()!, queue);
          } else if (item.getAlbum() != null) {
            model.onPlayAlbum(item.getAlbum()!);
          } else {}
        },
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
  late Future<List<StarredItem>> initialLoad;

  @override
  void initState() {
    super.initState();

    initialLoad = widget.model.onLoadStarred(false).then((value) {
      final data = [
        ...value.albums.entries
            .map((key) => StarredItem(album: key.value))
            .toList(),
        ...value.songs.entries
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
            return a.getAlbum()!.starredAt!.compareTo(b.getSong()!.starredAt!) *
                -1;
          }
        } else {
          if (b.getAlbum() != null) {
            return a.getSong()!.starredAt!.compareTo(b.getAlbum()!.starredAt!) *
                -1;
          } else {
            return a.getSong()!.starredAt!.compareTo(b.getSong()!.starredAt!) *
                -1;
          }
        }
      });

      return data;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<StarredItem>>(
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
