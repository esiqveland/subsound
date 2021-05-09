// Import the test package and Counter class
import 'package:subsound/components/player.dart';
import 'package:subsound/state/queue.dart';
import 'package:test/test.dart';

PlayerSong makeSong(String id) => PlayerSong(
      id: id,
      songTitle: id,
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

PlayerSong song1 = makeSong('1');
PlayerSong song2 = makeSong('2');
PlayerSong song3 = makeSong('3');
PlayerSong song4 = makeSong('4');

QueueItem item1Low = QueueItem(song1, QueuePriority.low);
QueueItem item1High = QueueItem(song2, QueuePriority.user);
QueueItem item2Low = QueueItem(song3, QueuePriority.low);
QueueItem item3High = QueueItem(song4, QueuePriority.user);

void main() {
  group('Queue', () {
    test('adding items', () {
      expect(Queue([]).length, 0);
      expect(Queue([]).add(item1Low).length, 1);
      expect(Queue([]).add(item1Low).add(item1High).length, 2);
      expect(Queue([]).addAll([item1Low, item1High]).length, 2);
    });

    test('adding items in prioritized order', () {
      expect(Queue([]).toList, []);
      expect(Queue([]).add(item1Low).toList, [item1Low]);
      expect(
        Queue([]).add(item1High).add(item1High).toList,
        [item1High, item1High],
      );
      expect(
        Queue([]).add(item1High).add(item1Low).toList,
        [item1High, item1Low],
      );
      expect(
        Queue([]).add(item1Low).add(item1High).toList,
        [item1High, item1Low],
      );
    });
    test('adding items in prioritized order with offset', () {
      expect(
        Queue([item1Low, item2Low], 1).add(item1High).toList,
        [item1Low, item2Low, item1High],
      );
      expect(
        Queue([item1Low, item2Low], 1).add(item1High).add(item3High).toList,
        [item1Low, item2Low, item1High, item3High],
      );
      expect(
        Queue([]).add(item1High).add(item1High).toList,
        [item1High, item1High],
      );
      expect(
        Queue([]).add(item1High).add(item1Low).toList,
        [item1High, item1Low],
      );
      expect(
        Queue([]).add(item1Low).add(item1High).toList,
        [item1High, item1Low],
      );
    });
  });
}
