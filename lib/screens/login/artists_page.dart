import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:subsound/components/covert_art.dart';
import 'package:subsound/screens/login/artist_page.dart';
import 'package:subsound/subsonic/context.dart';
import 'package:subsound/subsonic/requests/get_artists.dart';

class ArtistsPage extends StatefulWidget {
  final SubsonicContext ctx;

  const ArtistsPage({
    Key? key,
    required this.ctx,
  }) : super(key: key);

  @override
  State<ArtistsPage> createState() {
    return ArtistsPageState(ctx);
  }
}

class Header extends StatelessWidget {
  const Header({
    Key? key,
    required this.title,
    this.color = Colors.lightBlue,
  }) : super(key: key);

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      color: color,
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}

class ArtistIndexEntryWidget extends StatelessWidget {
  final ArtistIndexEntry entry;
  final Function(Artist) onSelected;

  const ArtistIndexEntryWidget({
    Key? key,
    required this.entry,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverStickyHeader(
      header: Header(
        title: entry.name,
        color: Colors.black12,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, idx) => InkWell(
            onTap: () {
              onSelected(entry.artist[idx]);
            },
            child: ListTile(
              leading: CoverArtImage(
                entry.artist[idx].coverArtLink,
                id: entry.artist[idx].coverArtId,
                height: 48.0,
                width: 48.0,
              ),
              title: Text("${entry.artist[idx].name}"),
              trailing: Text("${entry.artist[idx].albumCount}"),
            ),
          ),
          childCount: entry.artist.length,
        ),
      ),
    );
  }
}

class ArtistsPageState extends State<ArtistsPage> {
  final SubsonicContext ctx;

  ArtistsPageState(this.ctx);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: FutureBuilder<List<ArtistIndexEntry>>(
            future: load(),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return CircularProgressIndicator();
              } else {
                if (snapshot.hasError) {
                  return Text("${snapshot.error}");
                } else {
                  return DefaultStickyHeaderController(
                    child: CustomScrollView(
                      slivers: snapshot.data!
                          .map((a) => ArtistIndexEntryWidget(
                                entry: a,
                                onSelected: (entry) {
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) =>
                                        ArtistScreen(artistId: entry.id),
                                  ));
                                },
                              ))
                          .toList(),
                    ),
                  );
                }
              }
            }));
  }

  Future<List<ArtistIndexEntry>> load() {
    return GetArtistsRequest().run(ctx).then((value) => value.data.index);
  }
}
