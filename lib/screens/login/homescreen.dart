import 'package:async_redux/async_redux.dart';
import 'package:flutter/material.dart';
import 'package:subsound/screens/login/albums_page.dart';
import 'package:subsound/screens/login/artists_page.dart';
import 'package:subsound/state/appstate.dart';

import 'myscaffold.dart';

class HomeScreen extends StatelessWidget {
  static final routeName = "/home";

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, ServerData>(
      converter: (st) => st.state.loginState,
      builder: (context, state) => DefaultTabController(
        length: 2,
        child: MyScaffold(
          appBar: AppBar(
            bottom: TabBar(
              onTap: (idx) {},
              tabs: [
                Tab(
                  text: "Artists",
                ),
                Tab(
                  text: "Albums",
                ),
                //Tab(icon: Icon(Icons.add_shopping_cart)),
              ],
            ),
          ),
          body: (context) => Center(
            child: TabBarView(
              children: [
                Center(child: ArtistsPage(ctx: state.toClient())),
                Center(child: AlbumsPage(ctx: state.toClient())),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
