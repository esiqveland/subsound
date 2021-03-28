import 'dart:developer';

import 'package:async_redux/async_redux.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:subsound/components/miniplayer.dart';
import 'package:subsound/components/player.dart';
import 'package:subsound/screens/login/bottomnavbar.dart';
import 'package:subsound/screens/login/drawer.dart';
import 'package:subsound/screens/login/loginscreen.dart';
import 'package:subsound/state/appstate.dart';
import 'package:we_slide/we_slide.dart';

import 'homescreen.dart';

class SlidingHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WeSlide(
      body: Container(),
      panel: Container(),
      panelHeader: Container(),
      footer: BottomNavigationBar(
        items: [],
      ),
    );
  }
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
    Navigator.of(context).pushNamed(PlayerScreen.routeName);
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
final navBarItemsList = navBarItems.map((e) => e.item).toList();

class AppScaffoldModel extends Vm {
  final StartUpState startUpState;
  final bool hasSong;

  AppScaffoldModel({
    required this.startUpState,
    required this.hasSong,
  }) : super(equals: [startUpState, hasSong]);

  static AppScaffoldModel fromStore(Store<AppState> store) => AppScaffoldModel(
        startUpState: store.state.startUpState,
        hasSong: store.state.playerState.currentSong != null,
      );
}

const PlayerBottomBarSize = 50.0;

class MyScaffold extends StatelessWidget {
  final AppBar? appBar;
  final WidgetBuilder body;
  final Widget? title;
  final bool disableAppBar;
  final bool disableBottomBar;

  MyScaffold({
    Key? key,
    required this.body,
    this.appBar,
    this.title,
    this.disableAppBar = false,
    this.disableBottomBar = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, AppScaffoldModel>(
      converter: (store) => AppScaffoldModel.fromStore(store),
      builder: (context, state) => state.startUpState == StartUpState.loading
          ? SplashScreen()
          : _AppScaffold(
              title: title,
              body: body,
              appBar: appBar,
              disableAppBar: disableAppBar,
              disableBottomBar: disableBottomBar || !state.hasSong,
            ),
    );
  }
}

const Color bottomColor = Colors.black45;

class _AppScaffold extends StatelessWidget {
  final AppBar? appBar;
  final WidgetBuilder body;
  final Widget? title;
  final bool disableAppBar;
  final bool disableBottomBar;

  _AppScaffold({
    Key? key,
    required this.body,
    this.appBar,
    this.title,
    this.disableAppBar = false,
    this.disableBottomBar = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _colorScheme = Theme.of(context).colorScheme;
    final double _panelMinSize = PlayerBottomBarSize;
    final double _panelMaxSize = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: disableAppBar
          ? null
          : appBar ??
              AppBar(
                title: title,
              ),
      body: Builder(builder: body),
      drawer: Navigator.of(context).canPop() ? null : MyDrawer(),
      // bottomSheet: disableBottomBar
      //     ? null
      //     : PlayerBottomBar(
      //         height: PlayerBottomBarSize,
      //         backgroundColor: bottomColor,
      //       ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!disableBottomBar)
            PlayerBottomBar(
                height: PlayerBottomBarSize, backgroundColor: bottomColor),
          BottomNavigationBarWidget(
            navItems: navBarItems,
            backgroundColor: bottomColor,
          ),
        ],
      ),
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

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        //color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Sub",
              style: TextStyle(
                fontSize: 40.0,
                //color: Theme.of(context).primaryColor,
                //color: Colors.tealAccent,
                color: Colors.white,
                decoration: TextDecoration.none,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.0),
            Icon(
              Icons.play_arrow,
              size: 36.0,
            ),
            SizedBox(height: 20.0),
            Text(
              "Sound",
              style: TextStyle(
                fontSize: 32.0,
                //color: Theme.of(context).primaryColor,
                //color: Colors.tealAccent,
                color: Colors.white,
                decoration: TextDecoration.none,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.0),
            //CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
