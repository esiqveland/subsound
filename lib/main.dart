import 'dart:io';

import 'package:async_redux/async_redux.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:subsound/components/player.dart';
import 'package:subsound/screens/login/homescreen.dart';
import 'package:subsound/screens/login/loginscreen.dart';
import 'package:subsound/screens/login/myscaffold.dart';
import 'package:subsound/state/appstate.dart';
import 'package:subsound/state/player_task.dart';
import 'package:subsound/storage/cache.dart';

final Map<String, WidgetBuilder> appRoutes = {
  Navigator.defaultRouteName: (context) => RootScreen(),
  RootScreen.routeName: (context) => RootScreen(),
  HomeScreen.routeName: (context) => HomeScreen(),
  LoginScreen.routeName: (context) => LoginScreen(),
  PlayerScreen.routeName: (context) => PlayerScreen(),
};

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  if (Platform.isWindows || Platform.isLinux) {
    // Initialize FFI
    sqfliteFfiInit();
    // Change the default factory
    databaseFactory = databaseFactoryFfi;
  }

  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://873f2393ea7c458694f56f647100c224@o564637.ingest.sentry.io/5705472';
    },
    appRunner: () => runMain(),
  );
}

void runMain() async {
  WidgetsFlutterBinding.ensureInitialized();

  // store this in a singleton
  final h = await AudioService.init(
    builder: () => MyAudioHandler(),
    cacheManager: ArtworkCacheManager(),
    config: AudioServiceConfig(
      androidNotificationChannelName: 'SubSound',
      androidEnableQueue: true,
      // Enable this if you want the Android service to exit the foreground state on pause.
      androidStopForegroundOnPause: false,
      androidNotificationClickStartsActivity: true,
      androidShowNotificationBadge: false,
      // androidNotificationIcon: 'mipmap/ic_launcher',
      //params: DownloadAudioTask.createStartParams(),
    ),
  );

  // save handler as singleton
  audioHandler = h;

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  NavigateAction.setNavigatorKey(navigatorKey);

  final Store<AppState> store = createStore();
  store.dispatchFuture(StartupAction());

  runApp(MyApp(
    store: store,
  ));
}

final Color darkBlue = Color.fromARGB(255, 18, 32, 47);

class MyApp extends StatelessWidget {
  final Store<AppState> store;

  const MyApp({
    Key? key,
    required this.store,
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
