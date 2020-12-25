import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:subsound/components/player.dart';
import 'package:subsound/screens/login/artist_page.dart';
import 'package:subsound/screens/login/loginscreen.dart';

import 'homescreen.dart';

class MyScaffold extends StatelessWidget {
  final Widget body;

  const MyScaffold({Key key, this.body}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: body,
      drawer: Navigator.of(context).canPop()
          ? null
          : Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  DrawerHeader(
                    decoration: BoxDecoration(
                        //color: Colors.blue,
                        ),
                    child: Text(
                      'Subsound',
                      style: TextStyle(
                        //color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.settings),
                    title: Text("Settings"),
                    onTap: () {
                      Navigator.of(context).pushNamed(LoginScreen.routeName);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.music_note),
                    title: Text("Artists"),
                    onTap: () {
                      Navigator.of(context).pushNamed(HomeScreen.routeName);
                    },
                  ),
                  ListTile(
                      leading: Icon(Icons.album),
                      title: Text('Wilderun'),
                      onTap: () {
                        Navigator.of(context)
                            .pushNamed(WilderunScreen.routeName);
                      }),
                ],
              ),
            ),
      bottomSheet: PlayerBottomBar(),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            label: 'Music',
            icon: Icon(Icons.music_note),
          ),
          BottomNavigationBarItem(
            label: 'Player',
            icon: Icon(Icons.play_circle_outline_outlined),
          ),
          BottomNavigationBarItem(
            label: 'Settings',
            icon: Icon(Icons.settings),
          ),
        ],
      ),
    );
  }
}
