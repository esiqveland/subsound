import 'package:async_redux/async_redux.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:subsound/screens/browsing/starred_page.dart';
import 'package:subsound/screens/login/album_page.dart';
import 'package:subsound/screens/login/myscaffold.dart';
import 'package:subsound/state/appcommands.dart';
import 'package:subsound/state/appstate.dart';
import 'package:subsound/state/playerstate.dart';
import 'package:subsound/subsonic/requests/get_album.dart';
import 'package:subsound/subsonic/requests/get_playlist.dart';

class PlaylistViewModel extends Vm {
  final String currentSongId;
  final Function(SongResult, List<SongResult>) onPlay;
  final Function(SongResult) onEnqueue;
  final Future<GetPlaylistResult> Function(String) onLoadPlaylist;

  PlaylistViewModel({
    required this.currentSongId,
    required this.onPlay,
    required this.onEnqueue,
    required this.onLoadPlaylist,
  }) : super(equals: [currentSongId]);
}

class _PlaylistViewModelFactory extends VmFactory<AppState, PlaylistScreen, PlaylistViewModel> {
  _PlaylistViewModelFactory(PlaylistScreen widget) : super(widget);

  @override
  PlaylistViewModel fromStore() {
    return PlaylistViewModel(
      currentSongId: state.playerState.currentSong?.id ?? '',
      onEnqueue: (song) => dispatch(PlayerCommandEnqueueSong(song)),
      onPlay: (song, songs) => dispatch(PlayerCommandContextualPlay(
        songId: song.id,
        playQueue: songs,
      )),
      onLoadPlaylist: (playlistId) =>
          dispatchAsync(GetPlaylistCommand(playlistId)).then((value) =>
              currentState().dataState.playlists.playlistCache[playlistId]!),
    );
  }
}

class PlaylistScreen extends StatelessWidget {
  final String playlistId;

  PlaylistScreen({
    required this.playlistId,
  });

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, PlaylistViewModel>(
      vm: () => _PlaylistViewModelFactory(this),
      builder: (context, model) => MyScaffold(
        appBar: AppBarSettings(disableAppBar: true),
        body: (context) => Center(
          child: _PlaylistPage(
            playlistId: playlistId,
            model: model,
          ),
        ),
      ),
    );
  }
}

class _PlaylistPage extends StatefulWidget {
  final PlaylistViewModel model;
  final String playlistId;

  const _PlaylistPage({
    Key? key,
    required this.model,
    required this.playlistId,
  }) : super(key: key);

  @override
  State<_PlaylistPage> createState() {
    return _PlaylistPageState();
  }
}

class _PlaylistPageState extends State<_PlaylistPage> {
  late Future<GetPlaylistResult> data;

  @override
  void initState() {
    super.initState();
    data = widget.model.onLoadPlaylist(widget.playlistId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GetPlaylistResult>(
      future: data,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var playlist = snapshot.data!;
          return PlaylistPage(
            currentSongId: widget.model.currentSongId,
            playlist: playlist,
            onPlay: (song) => widget.model.onPlay(song, playlist.entries),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text("Error: ${snapshot.error}"),
          );
        } else {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}

class PlaylistPage extends StatelessWidget {
  final String currentSongId;
  final GetPlaylistResult playlist;
  final Function(SongResult) onPlay;

  PlaylistPage({
    Key? key,
    required this.currentSongId,
    required this.playlist,
    required this.onPlay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: playlist.entries.length,
        physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        itemBuilder: (context, idx) {
          var song = playlist.entries[idx];
          return StarredSongRow(
            song: song,
            isPlaying: currentSongId.isNotEmpty && song.id == currentSongId,
            onTapRow: onPlay,
            onTapCover: (song) {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => AlbumScreen(albumId: song.albumId),
              ));
            },
          );
        });
  }
}
