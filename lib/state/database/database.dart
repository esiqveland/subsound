import 'dart:developer';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:subsound/state/database/scrobbles_db.dart';

abstract class DatabaseAction<T> {
  Future<T> run(DB db);
}

/// Enable FOREIGN KEY constraints
Future<void> onConfigure(Database db) async {
  await db.execute('PRAGMA foreign_keys = ON');
}

Future<DB> openDB() async {
  // Avoid errors caused by flutter upgrade.
  WidgetsFlutterBinding.ensureInitialized();

  // Set the path to the database. Note: Using the `join` function from the
  // `path` package is best practice to ensure the path is correctly
  // constructed for each platform.
  var path = p.join(await getDatabasesPath(), 'app.db');
  var fd = File(path);
  if (fd.existsSync()) {
    log('deleting existing db at path=$path');
    fd.deleteSync();
  }

  log('opening sqlite db path=$path');

  var db = await openDatabase(
    path,
    version: 2,
    onConfigure: onConfigure,
    //onCreate and onUpdate is mutually exclusive.
    // we use onUpgrade to do all migrations, from v0 to vCurrent
    //onCreate: (db, version) {},
    onUpgrade: (db, oldVersion, newVersion) async {
      log('db: onUpgrade: oldVersion=$oldVersion newVersion=$newVersion');
      var batch = db.batch();
      if (oldVersion < 2) {
        ScrobbleData.createTableV1(batch);
      }
      await batch.commit();
    },
  );
  return DB(database: db);
}

class DBArtist {
  final String id;
  final String name;

  DBArtist(this.id, this.name);
}

class DBCachedResponse {
  final String id;
  final String serverId;
  final String request;
  final String response;

  DBCachedResponse(this.id, this.serverId, this.request, this.response);
}

class DBServer {
  final String id;
  final String uri;
  final String username;
  final String password;

  DBServer({
    required this.id,
    required this.uri,
    required this.username,
    required this.password,
  });

  void createTableV1(Batch tx) {
    tx.execute('''
        CREATE TABLE servers (
          id TEXT PRIMARY KEY,
          uri TEXT NOT NULL,
          username TEXT NOT NULL,
          password TEXT NOT NULL
        )
        ''');
  }
}

class DB {
  final Database database;

  DB({
    required Database database,
  }) : this.database = database;

  Future<void> close() async {
    await database.close();
  }
}
