import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:subsound/components/player.dart';
import 'package:subsound/screens/login/artist_page.dart';
import 'package:subsound/screens/login/loginscreen.dart';

import 'homescreen.dart';

class NavItems {
  final BottomNavigationBarItem item;
  final Function(BuildContext) handler;

  NavItems(this.item, this.handler);
}

final navBarItems = [
  NavItems(
    BottomNavigationBarItem(
      label: 'Music',
      icon: Icon(Icons.music_note),
    ),
    (context) {
      Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
    },
  ),
  NavItems(
      BottomNavigationBarItem(
        label: 'Player',
        icon: Icon(Icons.play_circle_outline_outlined),
      ), (context) {
    Navigator.of(context).pushReplacementNamed(PlayerScreen.routeName);
  }),
  NavItems(
      BottomNavigationBarItem(
        label: 'Search',
        icon: Icon(Icons.search_sharp),
      ), (context) {
    Navigator.of(context).pushReplacementNamed(PlayerScreen.routeName);
  }),
  NavItems(
    BottomNavigationBarItem(
      label: 'Settings',
      icon: Icon(Icons.settings),
    ),
    (context) {
      Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
    },
  )
];

class BottomNavigationBarWidget extends StatefulWidget {
  final List<NavItems> navItems;

  const BottomNavigationBarWidget({Key key, this.navItems}) : super(key: key);

  @override
  _BottomNavigationBarWidgetState createState() =>
      _BottomNavigationBarWidgetState(navItems: navItems);
}

class _BottomNavigationBarWidgetState extends State<BottomNavigationBarWidget> {
  int currentIndex;
  final List<NavItems> navItems;

  _BottomNavigationBarWidgetState({
    this.navItems,
    this.currentIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (idx) {
        navBarItems[idx].handler(context);
        setState(() {
          currentIndex = idx;
        });
      },
      items: navBarItems.map((item) => item.item).toList(),
    );
  }
}

const PlayerBottomBarSize = 50.0;

class MyScaffold extends StatelessWidget {
  final Widget appBar;
  final Widget body;
  bool disableAppBar;

  MyScaffold({
    Key key,
    this.body,
    this.appBar,
    this.disableAppBar = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: disableAppBar ? null : appBar ?? AppBar(),
      // body: Container(
      //   child: Column(
      //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //     children: [
      //       Expanded(child: body),
      //       Container(
      //         color: Colors.transparent.withOpacity(0.5),
      //         height: PlayerBottomBarSize,
      //       ),
      //     ],
      //   ),
      // ),
      body: Container(
        padding: EdgeInsets.only(bottom: PlayerBottomBarSize),
        child: body,
      ),
      drawer: Navigator.of(context).canPop()
          ? null
          : Drawer(
              child: Column(
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
      bottomSheet: PlayerBottomBar(size: PlayerBottomBarSize),
      bottomNavigationBar: BottomNavigationBarWidget(navItems: navBarItems),
    );
  }
}
