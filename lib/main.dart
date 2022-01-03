import 'dart:io';

import 'package:async_redux/async_redux.dart';
import 'package:audio_service/audio_service.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:multi_window/multi_window.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:subsound/app/app.dart';
import 'package:subsound/state/appstate.dart';
import 'package:subsound/state/database/database.dart';
import 'package:subsound/state/player_task.dart';
import 'package:subsound/storage/cache.dart';

final Logger logger = Logger("AppLogger");

void main(List<String> args) async {
  // logger.level = Level.ALL;
  // Logger.root.level = Level.ALL; // defaults to Level.INFO
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
    appRunner: () => runMain(args),
  );
}

void runMain(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isLinux || Platform.isWindows) {
    MultiWindow.init(args);
  }

  // store this in a singleton
  final h = await AudioService.init(
    builder: () => MyAudioHandler(),
    cacheManager: ArtworkCacheManager(),
    config: AudioServiceConfig(
      androidNotificationChannelName: 'SubSound',
      androidResumeOnClick: true,
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
  final DB db = await openDB();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  NavigateAction.setNavigatorKey(NavigatorKey);

  final Store<AppState> store = createStore();
  store.dispatch(StartupAction(db));

  runApp(MyApp(
    store: store,
  ));

  doWhenWindowReady(() {
    final initialSize = Size(1280, 720);
    appWindow.minSize = initialSize;
    appWindow.size = initialSize;
    appWindow.alignment = Alignment.center;
    appWindow.show();
  });
}

class MyApp extends StatelessWidget {
  final Store<AppState> store;

  const MyApp({
    Key? key,
    required this.store,
  }) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return StoreProvider(
      store: store,
      child: MainApp(),
    );
  }
}
