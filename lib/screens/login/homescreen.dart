import 'package:async_redux/async_redux.dart';
import 'package:flutter/material.dart';
import 'package:subsound/screens/login/artists_page.dart';
import 'package:subsound/state/appstate.dart';

import 'myscaffold.dart';

class HomeScreen extends StatelessWidget {
  static final routeName = "/home";

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, ServerData>(
      converter: (st) => st.state.loginState,
      builder: (context, state) => MyScaffold(
        body: (context) => Center(
          child: ArtistsPage(ctx: state.toClient()),
        ),
      ),
    );
  }
}
