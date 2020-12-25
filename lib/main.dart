import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:subsound/screens/login/homescreen.dart';
import 'package:subsound/screens/login/loginscreen.dart';

import 'screens/login/artist_page.dart';

final Map<String, WidgetBuilder> appRoutes = {
  Navigator.defaultRouteName: (context) => RootScreen(),
  RootScreen.routeName: (context) => RootScreen(),
  HomeScreen.routeName: (context) => HomeScreen(serverData: initialData),
  LoginScreen.routeName: (context) => LoginScreen(),
  WilderunScreen.routeName: (context) =>
      WilderunScreen(serverData: initialData),
};

class RootScreen extends StatelessWidget {
  static final routeName = "/root";

  Future<SharedPreferences> _shared = SharedPreferences.getInstance();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: _shared,
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.active:
          case ConnectionState.waiting:
            return SplashScreen();
          default:
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              ServerData data = ServerData.fromPrefs(snapshot.data);
              if (data.uri.isEmpty) {
                log("root:init:nostate data.uri=${data.uri}");
                //Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
                return LoginScreen();
              } else {
                log("root:init:state data.uri=${data.uri}");
                //Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
                return HomeScreen(serverData: initialData);
              }
            }
            return SplashScreen();
        }
      },
    );
  }
}

ServerData initialData;

void main() {
  SharedPreferences.getInstance().then((prefs) {
    final data = ServerData.fromPrefs(prefs);
    initialData = data;

    runApp(MyApp());
  });
}

final Color darkBlue = Color.fromARGB(255, 18, 32, 47);

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      //theme: ThemeData(primarySwatch: Colors.orange),
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: darkBlue),
      routes: appRoutes,
      initialRoute: Navigator.defaultRouteName,
    );
  }
}

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(),
    );
  }
}
