import 'dart:io' show Platform;
import 'package:adwaita/adwaita.dart' as adwaita;
import 'package:flutter/material.dart';
import 'package:subsound/components/player.dart';
import 'package:subsound/screens/login/homescreen.dart';
import 'package:subsound/screens/login/loginscreen.dart';
import 'package:subsound/screens/login/myscaffold.dart';

final Map<String, WidgetBuilder> appRoutes = {
  Navigator.defaultRouteName: (context) => RootScreen(),
  RootScreen.routeName: (context) => RootScreen(),
  HomeScreen.routeName: (context) => HomeScreen(),
  LoginScreen.routeName: (context) => LoginScreen(),
  PlayerScreen.routeName: (context) => PlayerScreen(),
};

final navigatorKey = GlobalKey<NavigatorState>();

class MainApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var theme = ThemeData.dark();
    var darkTheme = theme;

    if (Platform.isLinux) {
      theme = adwaita.AdwaitaThemeData.dark().copyWith(
        //backgroundColor: Colors.black,
        scaffoldBackgroundColor: Colors.black,
      );
      darkTheme = theme;
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      title: 'Sub:Sound',
      darkTheme: darkTheme,
      theme: theme.copyWith(
        bottomSheetTheme: theme.bottomSheetTheme.copyWith(
          backgroundColor: Colors.black.withOpacity(0.6),
        ),
      ),
      routes: appRoutes,
      initialRoute: Navigator.defaultRouteName,
    );
  }
}
