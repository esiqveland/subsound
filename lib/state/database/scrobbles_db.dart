import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import 'database.dart';

enum ScrobbleState {
  added,
  processing,
  done,
}

extension ScrobbleStates on ScrobbleState {
  String asString() {
    return describeEnum(this);
  }

  static ScrobbleState parse(String s) {
    switch (s) {
      case "done":
        return ScrobbleState.done;
      case "processing":
        return ScrobbleState.processing;
      case "added":
        return ScrobbleState.added;
      default:
        return ScrobbleState.added;
    }
  }
}

class DeleteScrobbleDatabaseAction extends DatabaseAction<int> {
  final String id;

  DeleteScrobbleDatabaseAction(this.id);

  @override
  Future<int> run(DB db) async {
    return await db.database.delete(
      ScrobbleData.tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

class CleanScrobbleDatabaseAction extends DatabaseAction<int> {
  @override
  Future<int> run(DB db) async {
    return await db.database.delete(
      ScrobbleData.tableName,
      where: "state = ?",
      whereArgs: [ScrobbleState.done.asString()],
    );
  }
}

class GetScrobbleBatchDatabaseAction
    extends DatabaseAction<List<ScrobbleData>> {
  @override
  Future<List<ScrobbleData>> run(DB db) async {
    var list = await db.database.query(
      ScrobbleData.tableName,
      where: "state = ?",
      whereArgs: [ScrobbleState.added.asString()],
      limit: 100,
    );

    var data = list
        .map((map) => ScrobbleData(
              id: map['id'] as String,
              songId: map['song_id'] as String,
              attempts: map['attempts'] as int,
              playedAt:
                  DateTime.fromMillisecondsSinceEpoch(map['played_at'] as int),
              state: ScrobbleStates.parse(map['state'] as String),
            ))
        .toList();

    return data;
  }
}

class PutScrobbleDatabaseAction extends DatabaseAction<ScrobbleData> {
  final ScrobbleData data;

  PutScrobbleDatabaseAction(this.data);

  @override
  Future<ScrobbleData> run(DB db) async {
    await db.database.insert(
      ScrobbleData.tableName,
      data.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return data;
  }
}

class ScrobbleData {
  static final String tableName = "scrobbles";

  final String id;
  final String songId;
  final int attempts;
  final DateTime playedAt;
  final ScrobbleState state;

  ScrobbleData({
    required this.id,
    required this.songId,
    required this.attempts,
    required this.playedAt,
    required this.state,
  });

  static void createTableV1(Batch tx) {
    tx.execute('''
        CREATE TABLE scrobbles (
          id TEXT PRIMARY KEY,
          song_id TEXT NOT NULL,
          attempts INT NOT NULL,
          played_at BIGINT NOT NULL,
          state TEXT NOT NULL
        )
        ''');
  }

  ScrobbleData attempted() => ScrobbleData(
        id: id,
        songId: songId,
        playedAt: playedAt,
        attempts: attempts + 1,
        state: state,
      );

  // The keys in the map must correspond to the names of the
  // columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'song_id': songId,
      'attempts': attempts,
      'played_at': playedAt.millisecondsSinceEpoch,
      'state': state.asString(),
    };
  }
}
