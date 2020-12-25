import 'package:flutter/material.dart';
import 'package:subsound/screens/login/artists_page.dart';
import 'package:subsound/screens/login/loginscreen.dart';
import 'package:subsound/subsonic/context.dart';

import 'myscaffold.dart';

class HomeScreen extends StatelessWidget {
  static final routeName = "/home";
  final ServerData serverData;
  final SubsonicContext client;

  HomeScreen({
    @required this.serverData,
  }) : client = SubsonicContext(
          serverId: serverData.uri,
          name: "",
          endpoint: Uri.tryParse(serverData.uri),
          // endpoint: null,
          user: serverData.username,
          pass: serverData.password,
        );

  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      body: Center(
        child: ArtistsPage(ctx: client),
      ),
    );
  }
}
