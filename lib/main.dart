import 'package:async_redux/async_redux.dart';
import 'package:flutter/material.dart';
import 'package:subsound/components/player.dart';
import 'package:subsound/screens/login/homescreen.dart';
import 'package:subsound/screens/login/loginscreen.dart';
import 'package:subsound/screens/login/myscaffold.dart';
import 'package:subsound/state/appstate.dart';

final Map<String, WidgetBuilder> appRoutes = {
  Navigator.defaultRouteName: (context) => RootScreen(),
  RootScreen.routeName: (context) => RootScreen(),
  HomeScreen.routeName: (context) => HomeScreen(),
  LoginScreen.routeName: (context) => LoginScreen(),
  PlayerScreen.routeName: (context) => PlayerScreen(),
};

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  NavigateAction.setNavigatorKey(navigatorKey);

  final Store<AppState> store = createStore();
  store.dispatch(StartupAction());
  runApp(MyApp(
    store: store,
  ));
}

final Color darkBlue = Color.fromARGB(255, 18, 32, 47);

class MyApp extends StatelessWidget {
  final Store<AppState> store;

  const MyApp({
    Key key,
    @required this.store,
  }) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    var theme = ThemeData.dark();
    return StoreProvider(
      store: store,
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Sub:Sound',
        theme: theme.copyWith(
          bottomSheetTheme: theme.bottomSheetTheme.copyWith(
            backgroundColor: Colors.black.withOpacity(0.6),
          ),
        ),
        routes: appRoutes,
        initialRoute: Navigator.defaultRouteName,
      ),
    );
  }
}
