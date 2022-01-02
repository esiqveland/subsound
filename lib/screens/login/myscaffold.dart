import 'dart:developer';
import 'dart:io';

import 'package:async_redux/async_redux.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:libadwaita/libadwaita.dart';
import 'package:subsound/components/miniplayer.dart';
import 'package:subsound/components/player.dart';
import 'package:subsound/screens/browsing/home_page.dart';
import 'package:subsound/screens/browsing/search.dart';
import 'package:subsound/screens/browsing/starred_page.dart';
import 'package:subsound/screens/login/albums_page.dart';
import 'package:subsound/screens/login/artist_page.dart';
import 'package:subsound/screens/login/artists_page.dart';
import 'package:subsound/screens/login/bottomnavbar.dart';
import 'package:subsound/screens/login/drawer.dart';
import 'package:subsound/screens/login/loginscreen.dart';
import 'package:subsound/screens/login/settings_page.dart';
import 'package:subsound/state/appstate.dart';
import 'package:we_slide/we_slide.dart';
import 'package:window_decorations/window_decorations.dart';

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
        label: 'Search',
        icon: Icon(Icons.search),
      ), (context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => SearchScreen(),
    ));
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
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => SettingsPage()));
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

const playerBottomBarSize = 50.0;

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
              builder: body,
              appBar: appBar ?? AppBarSettings(),
              disableBottomBar: disableBottomBar || !state.hasSong,
            ),
    );
  }
}

final Color bottomColor = Colors.black26.withOpacity(1.0);

class LinuxBody extends StatefulWidget {
  final WidgetBuilder builder;

  const LinuxBody({
    Key? key,
    required this.builder,
  }) : super(key: key);

  @override
  _LinuxBodyState createState() => _LinuxBodyState();
}

class ViewSwitcherEntry {
  final ViewSwitcherData data;
  final WidgetBuilder builder;
  final Function(BuildContext) goto;

  ViewSwitcherEntry({
    required this.data,
    required this.builder,
    required this.goto,
  });
}

final List<ViewSwitcherEntry> linuxTabs = [
  ViewSwitcherEntry(
    data: ViewSwitcherData(title: "Home", icon: Icons.home),
    builder: (context) => HomeScreen(initialTabIndex: 0),
    goto: (context) {
      //Navigator.pushNamed(context, HomeScreen.routeName);
    },
  ),
  ViewSwitcherEntry(
    data: ViewSwitcherData(
      title: "Artists",
      icon: Icons.group,
    ),
    builder: (context) => ArtistsPage(),
    goto: (context) {
      //Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ArtistsPage()));
    },
  ),
  ViewSwitcherEntry(
    data: ViewSwitcherData(
      title: "Albums",
      icon: Icons.album,
    ),
    builder: (context) => ArtistsPage(),
    goto: (context) {
      //Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ArtistsPage()));
    },
  ),
  ViewSwitcherEntry(
    data: ViewSwitcherData(
      title: "Starred",
      icon: Icons.search,
    ),
    builder: (context) => StarredPage(),
    goto: (context) {
      //Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => StarredPage()));
    },
  ),
];

class _LinuxBodyState extends State<LinuxBody> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AdwHeaderBar.bitsdojo(
          appWindow: appWindow,
          windowDecor: windowDecor,
          themeType: ThemeType.adwaita,
          showClose: true,
          showMaximize: true,
          showMinimize: true,
          start: Row(
            children: [
              Builder(
                builder: (context) {
                  return AdwHeaderButton(
                    icon: const Icon(Icons.view_sidebar, size: 15),
                    isActive: false,
                    onPressed: () {
                      //_flapController.toggle();
                    },
                  );
                },
              ),
            ],
          ),
          title: AdwViewSwitcher(
            currentIndex: index,
            onViewChanged: (idx) {
              setState(() {
                index = idx;
              });
            },
            expanded: false,
            style: ViewSwitcherStyle.desktop,
            tabs: linuxTabs.map((e) => e.data)
                .toList(growable: false),
          ),
          end: Row(
            children: [
              AdwPopupMenu(
                body: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      onTap: () {},
                      title: const Text(
                        'Force reload',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    ListTile(
                      onTap: () {},
                      title: const Text(
                        'Settings',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0),
            child: AdwViewStack(
              index: index,
              children: [
                HomePage(),
                ArtistsPage(),
                AlbumsPage(),
                StarredPage(),
              ],
              // children: linuxTabs
              //     .map((e) => e.builder)
              //     .map((e) => Builder(builder: e))
              //     .toList(growable: false),
            ),
          ),
        ),
      ],
    );
  }
}

class MainBody extends StatelessWidget {
  final AppBarSettings appBar;
  final bool disableBottomBar;
  final WidgetBuilder builder;

  MainBody({
    Key? key,
    required this.appBar,
    required this.builder,
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
        disableBottomBar ? footerHeight : playerBottomBarSize + footerHeight;
    final double _panelMaxSize = MediaQuery.of(context).size.height;

    if (Platform.isLinux) {
      return LinuxBody(builder: builder);
    }

    return WeSlide(
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
            child: Builder(builder: builder),
          ),
        ],
      ),
      panel: disableBottomBar
          ? SizedBox()
          : Container(
              child: PlayerView(
                backgroundColor: Theme.of(context).primaryColor,
                header: Text(
                  "Now Playing",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20.0),
                ),
              ),
            ),
      panelHeader: disableBottomBar
          ? SizedBox()
          : Container(
              child: PlayerBottomBar(
                height: playerBottomBarSize,
                backgroundColor: Theme.of(context).primaryColor,
                onTap: () {
                  _controller.show();
                },
              ),
            ),
      footerHeight: footerHeight,
      footer: BottomNavigationBarWidget(
        navItems: navBarItems,
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }
}

class _AppScaffold extends StatelessWidget {
  final AppBarSettings appBar;
  final WidgetBuilder builder;
  final bool disableBottomBar;

  _AppScaffold({
    Key? key,
    required this.builder,
    required this.appBar,
    this.disableBottomBar = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var bodyHolder = MainBody(
      appBar: appBar,
      disableBottomBar: disableBottomBar,
      builder: builder,
    );
    if (Platform.isLinux) {
      return AdwScaffold(
        drawer: Navigator.of(context).canPop() ? null : MyDrawer(),
        body: bodyHolder,
      );
    } else {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        body: bodyHolder,
        drawer: Navigator.of(context).canPop() ? null : MyDrawer(),
      );
    }
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
            Positioned(
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
