import 'dart:developer';

import 'package:async_redux/async_redux.dart';
import 'package:flutter/material.dart';
import 'package:subsound/components/miniplayer.dart';
import 'package:subsound/components/player.dart';
import 'package:subsound/screens/login/loginscreen.dart';
import 'package:subsound/state/appstate.dart';

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
  // NavItems(
  //     BottomNavigationBarItem(
  //       label: 'Search',
  //       icon: Icon(Icons.search_sharp),
  //     ), (context) {
  //   Navigator.of(context).pushReplacementNamed(PlayerScreen.routeName);
  // }),
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
  final WidgetBuilder body;
  final Widget title;
  final bool disableAppBar;

  MyScaffold({
    Key key,
    this.body,
    this.appBar,
    this.title,
    this.disableAppBar = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, StartUpState>(
      converter: (state) => state.state.startUpState,
      builder: (context, state) => state == StartUpState.loading
          ? _SplashScreen()
          : _AppScaffold(
              title: title,
              body: body,
              appBar: appBar,
              disableAppBar: disableAppBar,
            ),
    );
  }
}

class _AppScaffold extends StatelessWidget {
  final Widget appBar;
  final WidgetBuilder body;
  final Widget title;
  final bool disableAppBar;

  _AppScaffold({
    Key key,
    this.body,
    this.appBar,
    this.title,
    this.disableAppBar = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: disableAppBar
          ? null
          : appBar ??
              AppBar(
                title: title,
              ),
      body: Container(
        padding: EdgeInsets.only(bottom: PlayerBottomBarSize),
        child: Builder(
          builder: body,
        ),
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
                ],
              ),
            ),
      bottomSheet: PlayerBottomBar(height: PlayerBottomBarSize),
      bottomNavigationBar: BottomNavigationBarWidget(navItems: navBarItems),
    );
  }
}

class RootScreen extends StatelessWidget {
  static final routeName = "/root";

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, ServerData>(
      converter: (store) => store.state.loginState,
      builder: (context, data) {
        if (data.uri.isEmpty || Uri.tryParse(data.uri) == null) {
          log("root:init:nostate data.uri=${data.uri}");
          //Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
          return LoginScreen();
        } else {
          log("root:init:state data.uri=${data.uri}");
          //Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
          return HomeScreen();
        }
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        //color: Colors.white,
        child: Column(
          children: [
            Icon(
              Icons.play_arrow_outlined,
              size: 36.0,
            ),
            Text(
              "Sub:Sound",
              style: TextStyle(fontSize: 40.0),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
