import 'package:async_redux/async_redux.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:subsound/screens/browsing/home_page.dart';
import 'package:subsound/screens/login/myscaffold.dart';
import 'package:subsound/state/appcommands.dart';
import 'package:subsound/state/appstate.dart';
import 'package:subsound/state/playerstate.dart';
import 'package:subsound/subsonic/requests/get_album.dart';
import 'package:subsound/subsonic/requests/get_artist.dart';
import 'package:subsound/subsonic/requests/search3.dart';

class SearchScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      appBar: AppBarSettings(disableAppBar: true),
      body: (context) => CustomScrollView(
        primary: true,
        physics: BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverAppBar(),
          SliverToBoxAdapter(child: SearchField()),
        ],
      ),
    );
  }
}

class SearchField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _SearchModel>(
      vm: () => _SearchModelFactory(this),
      builder: (context, model) {
        return _SearchMusic(model: model);
      },
    );
  }
}

class _SearchModelFactory extends VmFactory<AppState, SearchField, _SearchModel> {
  _SearchModelFactory(SearchField widget) : super(widget);

  @override
  _SearchModel fromStore() {
    return _SearchModel(
      currentPlayingId: state.playerState.currentSong?.id ?? '',
      onPlaySong: (SongResult song, List<SongResult> playQueue) =>
          dispatchAsync(PlayerCommandContextualPlay(
        songId: song.id,
        playQueue: playQueue,
      )),
      onPlayAlbum: (album) => dispatchAsync(PlayerCommandPlayAlbum(album)),
      onSearch: (query) => dispatchAsync(SearchCommand(query))
          .then((value) => currentState().dataState.searches.get(query))
          .then((value) => value.data),
    );
  }
}

class _SearchModel extends Vm {
  final Future<Search3Result> Function(String) onSearch;
  final Future<void> Function(SongResult, List<SongResult>) onPlaySong;
  final Future<void> Function(AlbumResultSimple) onPlayAlbum;
  final String currentPlayingId;

  _SearchModel({
    required this.onSearch,
    required this.onPlaySong,
    required this.onPlayAlbum,
    required this.currentPlayingId,
  }) : super(equals: [currentPlayingId]);
}

class _SearchMusic extends StatefulWidget {
  final _SearchModel model;

  const _SearchMusic({
    Key? key,
    required this.model,
  }) : super(key: key);

  @override
  State<_SearchMusic> createState() {
    return _SearchMusicState();
  }
}

class _SearchMusicState extends State<_SearchMusic> {
  Search3Result? result;
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    // List<StarredItem> artistResults =
    //     result?.artists.map((e) => StarredItem(album: e)).toList() ?? [];

    List<StarredItem> albumResults =
        result?.albums.map((e) => StarredItem(album: e)).toList() ?? [];

    List<StarredItem> songResults =
        result?.songs.map((e) => StarredItem(song: e)).toList() ?? [];

    return CustomScrollView(
      primary: false,
      shrinkWrap: true,
      slivers: [
        SliverToBoxAdapter(
          child: CupertinoSearchTextField(
            onChanged: (val) {
              if (val.isEmpty) {
                setState(() {
                  result = null;
                });
              }
            },
            onSubmitted: (val) {
              setState(() {
                result = null;
                loading = true;
              });
              if (val.isEmpty) {
                return;
              }
              widget.model
                  .onSearch(val)
                  .then((response) => setState(() {
                        result = response;
                      }))
                  .whenComplete(() => setState(() {
                        loading = false;
                      }));
            },
          ),
        ),
        SliverToBoxAdapter(child: HomePageTitle("Artists")),
        SliverToBoxAdapter(child: HomePageTitle("Albums")),
        if (!loading)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, idx) {
                return StarredRow(
                  item: albumResults[idx],
                  isPlaying: albumResults[idx]
                      .isPlaying(widget.model.currentPlayingId),
                  onPlay: (starredItem) {
                    if (starredItem.getSong() != null) {
                      var queue = songResults
                          .where((element) => element.getSong() != null)
                          .map((e) => e.getSong()!)
                          .toList();
                      widget.model.onPlaySong(starredItem.getSong()!, queue);
                    } else if (starredItem.getAlbum() != null) {
                      widget.model.onPlayAlbum(starredItem.getAlbum()!);
                    } else {}
                  },
                );
              },
              childCount: albumResults.length,
            ),
          ),
        SliverToBoxAdapter(
          child: HomePageTitle("Songs"),
        ),
        if (!loading)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, idx) {
                return StarredRow(
                  item: songResults[idx],
                  isPlaying:
                      songResults[idx].isPlaying(widget.model.currentPlayingId),
                  onPlay: (starredItem) {
                    if (starredItem.getSong() != null) {
                      var queue = songResults
                          .where((element) => element.getSong() != null)
                          .map((e) => e.getSong()!)
                          .toList();
                      widget.model.onPlaySong(starredItem.getSong()!, queue);
                    } else if (starredItem.getAlbum() != null) {
                      widget.model.onPlayAlbum(starredItem.getAlbum()!);
                    } else {}
                  },
                );
              },
              childCount: songResults.length,
            ),
          ),
      ],
    );
  }
}
