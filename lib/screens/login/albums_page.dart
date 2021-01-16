import 'package:flutter/material.dart';
import 'package:subsound/components/covert_art.dart';
import 'package:subsound/screens/login/album_page.dart';
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
  final Function(Album) onTap;

  const AlbumRow({
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
      leading: Hero(
        tag: album.coverArtId,
        child: CoverArtImage(
          album.coverArtLink,
          id: album.coverArtId,
          width: 48.0,
          height: 48.0,
        ),
      ),
      title: Text(album.title),
      subtitle: Text(album.artist),
    );
  }
}

class AlbumsListView extends StatelessWidget {
  final SubsonicContext ctx;
  final List<Album> albums;
  final ScrollController controller;
  final bool isLoading;

  const AlbumsListView({
    Key key,
    this.ctx,
    this.albums,
    this.controller,
    this.isLoading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: BouncingScrollPhysics(),
      controller: controller,
      itemCount: albums.length,
      itemBuilder: (context, idx) => Column(
        children: [
          AlbumRow(
            album: albums[idx],
            onTap: (album) {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => AlbumScreen(
                  albumId: album.id,
                ),
              ));
            },
          ),
          if (isLoading && idx == albums.length - 1)
            CircularProgressIndicator(),
        ],
      ),
    );
  }
}

class AlbumsPageState extends State<AlbumsPage> {
  final SubsonicContext ctx;

  final int pageSize = 10;
  List<Album> _albumList = [];
  bool hasMore = true;
  bool isLoading = false;
  ScrollController _controller;

  Future<List<Album>> initialLoad;

  AlbumsPageState(this.ctx);

  @override
  void initState() {
    super.initState();
    _controller = new ScrollController();
    isLoading = true;
    initialLoad = load(offset: 0, pageSize: pageSize).then((value) {
      if (!this.mounted) {
        return value;
      }
      setState(() {
        isLoading = false;
        _albumList.addAll(value);
      });
      return value;
    });
    initialLoad.whenComplete(() {
      if (!this.mounted) {
        return;
      }
      setState(() {
        isLoading = false;
      });
    });
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollEndNotification) {
      if (_controller.position.extentAfter == 0) {
        loadMore();
      }
    }
    return false;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: Center(
          child: FutureBuilder<List<Album>>(
              future: initialLoad,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return CircularProgressIndicator();
                } else {
                  if (snapshot.hasError) {
                    return Text("${snapshot.error}");
                  } else {
                    _albumList = snapshot.data;
                    return AlbumsListView(
                      ctx: ctx,
                      controller: _controller,
                      albums: _albumList,
                      isLoading: isLoading,
                    );
                  }
                }
              })),
    );
  }

  Future<List<Album>> loadMore() {
    if (hasMore && !isLoading) {
      setState(() {
        isLoading = true;
      });
      load(
        pageSize: 10,
        offset: _albumList.length,
      ).then((value) {
        setState(() {
          _albumList.addAll(value);
          isLoading = false;
        });
      }).whenComplete(() => {
            setState(() {
              isLoading = false;
            })
          });
    }
  }

  Future<List<Album>> load({
    int pageSize = 50,
    int offset = 0,
  }) {
    return GetAlbumList2(
      type: GetAlbumListType.alphabeticalByName,
      size: pageSize,
      offset: offset,
    ).run(ctx).then((value) => value.data).then((List<Album> nextList) {
      if (nextList.length < pageSize) {
        setState(() {
          hasMore = false;
        });
      }
      return nextList;
    });
  }
}
