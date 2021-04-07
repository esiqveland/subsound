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

/// AppBarSettings exists because we sometimes need a SliverAppBar
/// and sometimes a regular AppBar.
class AppBarSettings {
  final bool disableAppBar;
  final bool centerTitle;
  final bool floating;
  final bool pinned;
  final Widget? title;
  final PreferredSizeWidget? bottom;

  AppBarSettings({
    this.disableAppBar = false,
    this.centerTitle = false,
    this.floating = false,
    this.pinned = false,
    this.title,
    this.bottom,
  });
}

const PlayerBottomBarSize = 50.0;

class MyScaffold extends StatelessWidget {
  final AppBarSettings? appBar;
  final WidgetBuilder body;
  final bool disableBottomBar;

  MyScaffold({
    Key? key,
    required this.body,
    this.appBar,
    this.disableBottomBar = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, AppScaffoldModel>(
      converter: (store) => AppScaffoldModel.fromStore(store),
      builder: (context, state) => state.startUpState == StartUpState.loading
          ? SplashScreen()
          : _AppScaffold(
              body: body,
              appBar: appBar ?? AppBarSettings(),
              disableBottomBar: disableBottomBar || !state.hasSong,
            ),
    );
  }
}

final Color bottomColor = Colors.black26.withOpacity(1.0);

class _AppScaffold extends StatelessWidget {
  final AppBarSettings appBar;
  final WidgetBuilder body;
  final bool disableBottomBar;

  _AppScaffold({
    Key? key,
    required this.body,
    required this.appBar,
    this.disableBottomBar = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final bool disableAppBar = appBar.disableAppBar;
    final WeSlideController _controller = WeSlideController();
    final footerHeight =
        kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;
    final double _panelMinSize =
        disableBottomBar ? footerHeight : PlayerBottomBarSize + footerHeight;
    final double _panelMaxSize = MediaQuery.of(context).size.height;

    return Scaffold(
      body: WeSlide(
        controller: _controller,
        panelMinSize: _panelMinSize,
        panelMaxSize: _panelMaxSize,
        hidePanelHeader: true,
        hideFooter: true,
        parallax: false,
        overlayOpacity: 1.0,
        overlayColor: bgColor,
        backgroundColor: bgColor,
        overlay: true,
        body: CustomScrollView(
          slivers: <Widget>[
            if (!disableAppBar)
              SliverAppBar(
                title: appBar.title,
                centerTitle: appBar.centerTitle,
                floating: appBar.floating,
                pinned: appBar.pinned,
                bottom: appBar.bottom,
              ),
            SliverFillRemaining(
              hasScrollBody: true,
              child: Builder(builder: body),
            ),
          ],
        ),
        panel: Container(
          child: PlayerView(
            backgroundColor: bgColor,
            header: Text(
              "Now Playing",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20.0),
            ),
          ),
        ),
        panelHeader: Container(
          child: PlayerBottomBar(
            height: PlayerBottomBarSize,
            backgroundColor: bgColor,
            onTap: () {
              _controller.show();
            },
          ),
        ),
        footerHeight: footerHeight,
        footer: BottomNavigationBarWidget(
          navItems: navBarItems,
          backgroundColor: bottomColor,
        ),
      ),
      drawer: Navigator.of(context).canPop() ? null : MyDrawer(),
    );
  }
}

class TestAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      title: Text("This is a title"),
      // bottom: TabBar(
      //   tabs: [
      //     Tab(
      //       text: "Tab1",
      //     ),
      //     Tab(
      //       text: "Tab2",
      //     ),
      //     Tab(
      //       text: "Tab3",
      //     ),
      //   ],
      // ),
    );
  }
}

class TestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final double _panelMinSize = 150.0;
    final double _panelMaxSize = MediaQuery.of(context).size.height;

    return Scaffold(
      // appBar: AppBar(
      //   title: Text("This is a title"),
      //   bottom: TabBar(
      //     tabs: [
      //       Tab(
      //         text: "Tab1",
      //       ),
      //       Tab(
      //         text: "Tab2",
      //       ),
      //       Tab(
      //         text: "Tab3",
      //       ),
      //     ],
      //   ),
      // ),
      backgroundColor: Colors.black,
      body: WeSlide(
        panelMinSize: _panelMinSize,
        panelMaxSize: _panelMaxSize,
        footerHeight: 60.0,
        body: Stack(
          children: <Widget>[
            Container(
              color: Colors.red,
              child: Center(child: Text("This is the body 💪")),
            ),
            new Positioned(
              top: 0.0,
              left: 0.0,
              right: 0.0,
              child: TestAppBar(),
            ),
          ],
        ),
        panel: Container(
          color: Colors.blue,
          child: Center(child: Text("This is the panel 😊")),
        ),
        panelHeader: Container(
          height: _panelMinSize,
          color: Colors.green,
          child: Center(child: Text("Slide to Up ☝️")),
        ),
        footer: Container(
          height: 60.0,
          color: Colors.amber,
        ),
      ),
    );
  }
}

class TestApp2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final double _panelMinSize = 150.0;
    final double _panelMaxSize = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: WeSlide(
        panelMinSize: _panelMinSize,
        panelMaxSize: _panelMaxSize,
        footerHeight: 60.0,
        body: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              title: Text("Title"),
              bottom: TabBar(
                tabs: [
                  Tab(
                    text: "Tab1",
                  ),
                  Tab(
                    text: "Tab2",
                  ),
                  Tab(
                    text: "Tab3",
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                color: Colors.red,
                height: 5000,
                child: Text("body"),
              ),
            ),
          ],
        ),
        panel: Container(
          color: Colors.blue,
          child: Center(child: Text("This is the panel 😊")),
        ),
        panelHeader: Container(
          height: _panelMinSize,
          color: Colors.green,
          child: Center(child: Text("Slide to Up ☝️")),
        ),
        footer: Container(
          height: 60.0,
          color: Colors.amber,
        ),
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
