// Import the test package and Counter class
import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:subsound/components/player.dart';
import 'package:subsound/state/database/database.dart';
import 'package:test/test.dart';

PlayerSong song1 = PlayerSong(
  id: '',
  songTitle: '',
  artist: '',
  album: '',
  artistId: '',
  albumId: '',
  coverArtId: '',
  songUrl: '',
  contentType: '',
  fileExtension: '',
  fileSize: 1,
  duration: Duration.zero,
);

void main() {
  if (Platform.isWindows || Platform.isLinux) {
    // Initialize FFI
    sqfliteFfiInit();
    // Change the default factory
    databaseFactory = databaseFactoryFfi;
  }
  group('Database', () {
    test('creating', () async {
      final db = await openDB();
    });
    test('migrations', () {});
    test('adding server', () {});
  });
}
