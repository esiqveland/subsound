import 'package:async_redux/async_redux.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:subsound/components/covert_art.dart';
import 'package:subsound/screens/login/album_page.dart';
import 'package:subsound/state/appstate.dart';
import 'package:subsound/subsonic/context.dart';
import 'package:subsound/subsonic/models/album.dart';
import 'package:subsound/subsonic/requests/get_album_list.dart';
import 'package:subsound/subsonic/requests/get_album_list2.dart';

class AlbumsPage extends StatelessWidget {
  const AlbumsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, SubsonicContext>(
      converter: (store) => store.state.loginState.toClient(),
      builder: (context, vm) => AlbumsPageHolder(ctx: vm),
    );
  }
}

class AlbumsPageHolder extends StatefulWidget {
  final SubsonicContext ctx;

  const AlbumsPageHolder({Key? key, required this.ctx}) : super(key: key);

  @override
  State<AlbumsPageHolder> createState() {
    return AlbumsPageState();
  }
}

class AlbumsPageState extends State<AlbumsPageHolder> {
  final int pageSize = 100;
  late ScrollController _controller;
  late Future<List<Album>> initialLoad;

  List<Album> _albumList = [];
  bool hasMore = true;
  bool isLoading = false;

  AlbumsPageState();

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    isLoading = true;
    initialLoad = load(offset: 0, pageSize: pageSize).then((value) {
      if (!mounted) {
        return value;
      }
      setState(() {
        isLoading = false;
        _albumList.addAll(value);
      });
      return value;
    });
    initialLoad.whenComplete(() {
      if (!mounted) {
        return;
      }
      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: FutureBuilder<List<Album>>(
            future: initialLoad,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return CircularProgressIndicator();
              } else {
                if (snapshot.hasError) {
                  return Text("${snapshot.error}");
                } else {
                  _albumList = snapshot.data!;
                  return AlbumsListView(
                    controller: _controller,
                    albums: _albumList,
                    isLoading: isLoading,
                    loadMore: loadMore,
                  );
                }
              }
            }));
  }

  Future<void> loadMore() {
    if (hasMore && !isLoading) {
      setState(() {
        isLoading = true;
      });

      return load(
        pageSize: pageSize,
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
    return Future.value(null);
  }

  Future<List<Album>> load({
    required int pageSize,
    int offset = 0,
  }) {
    return GetAlbumList2(
      type: GetAlbumListType.alphabeticalByName,
      size: pageSize,
      offset: offset,
    ).run(widget.ctx).then((value) => value.data).then((List<Album> nextList) {
      if (nextList.length < pageSize) {
        setState(() {
          hasMore = false;
        });
      }
      return nextList;
    });
  }
}

class AlbumRow extends StatelessWidget {
  final Album album;
  final Function(Album) onTap;

  const AlbumRow({
    Key? key,
    required this.album,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        onTap(album);
      },
      leading: CoverArtImage(
        album.coverArtLink,
        id: album.coverArtId,
        width: 48.0,
        height: 48.0,
      ),
      title: Text(album.title),
      subtitle: Text(album.artist),
    );
  }
}

class AlbumItem extends StatelessWidget {
  final Album album;
  final Function(Album) onTap;
  final double width;

  const AlbumItem({
    Key? key,
    required this.album,
    required this.onTap,
    required this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = EdgeInsets.all(8.0);

    return Material(
      child: InkWell(
        hoverColor: Theme.of(context).hoverColor,
        onTap: () {
          onTap(album);
        },
        child: Container(
          padding: padding,
          width: width,
          child: Column(
            //mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20.0),
                child: Container(
                  color: Colors.redAccent,
                  child: CoverArtImage(
                    album.coverArtLink,
                    id: album.coverArtId,
                    width: width - padding.left - padding.right,
                    height: width - padding.left - padding.right,
                    fit: BoxFit.fitWidth,
                  ),
                ),
              ),
              Text(
                album.title,
                style: theme.textTheme.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2.0),
              Text(
                album.artist,
                style: theme.textTheme.caption!.copyWith(fontSize: 14.0),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AlbumsListView extends StatelessWidget {
  final List<Album> albums;
  final ScrollController controller;
  final bool isLoading;
  final void Function() loadMore;

  const AlbumsListView({
    Key? key,
    required this.albums,
    required this.controller,
    required this.isLoading,
    required this.loadMore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    SliverMultiBoxAdaptorWidget sliver = SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, idx) {
          return AlbumRow(
            album: albums[idx],
            onTap: (album) {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => AlbumScreen(
                  albumId: album.id,
                ),
              ));
            },
          );
        },
        childCount: albums.length,
      ),
    );
    if (media.size.width >= 700) {
      const itemWidth = 240.0;
      final maxCrossAxisExtent = 0.95 * media.size.width / itemWidth;

      sliver = SliverGrid(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: itemWidth,
          mainAxisSpacing: 15.0,
          crossAxisSpacing: 30.0,
          childAspectRatio: 0.7,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, idx) {
            return AlbumItem(
              width: itemWidth,
              album: albums[idx],
              onTap: (album) {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => AlbumScreen(
                    albumId: album.id,
                  ),
                ));
              },
            );
          },
          childCount: albums.length,
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: CustomScrollView(
        controller: controller,
        physics: BouncingScrollPhysics(),
        slivers: <Widget>[
          sliver,
          if (isLoading)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                child: Center(
                  child: SizedBox(
                      height: 30,
                      width: 30,
                      child: CircularProgressIndicator()),
                ),
              ),
            )
        ],
      ),
    );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollEndNotification) {
      if (controller.position.extentAfter == 0) {
        loadMore();
      }
    }
    return false;
  }
}
