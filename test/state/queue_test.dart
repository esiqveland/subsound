// Import the test package and Counter class
import 'package:subsound/components/player.dart';
import 'package:subsound/state/queue.dart';
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
QueueItem item1Low = QueueItem(song1, QueuePriority.low);
QueueItem item1High = QueueItem(song1, QueuePriority.user);
QueueItem item2Low = QueueItem(song1, QueuePriority.low);
QueueItem item3High = QueueItem(song1, QueuePriority.user);

void main() {
  group('Queue', () {
    test('adding items', () {
      expect(Queue([]).length, 0);
      expect(Queue([]).add(item1Low).length, 1);
      expect(Queue([]).add(item1Low).add(item1High).length, 2);
      expect(Queue([]).addAll([item1Low, item1High]).length, 2);
    });

    test('replaces items in prioritized order', () {
      expect(Queue([]).replaceWith([]).copy, []);
      expect(
        Queue([]).replaceWith([item1High, item1Low]).copy,
        [item1High, item1Low],
      );
      expect(
        Queue([]).replaceWith([item1Low, item1High]).copy,
        [item1High, item1Low],
      );
      expect(
        Queue([]).replaceWith([item1Low, item1High, item2Low]).copy,
        [item1High, item1Low, item2Low],
      );
      expect(
        Queue([]).replaceWith([item1Low, item1High, item2Low, item3High]).copy,
        [item1High, item3High, item1Low, item2Low],
      );
    });
    test('adding items in prioritized order', () {
      expect(Queue([]).copy, []);
      expect(Queue([]).add(item1Low).copy, [item1Low]);
      expect(
        Queue([]).add(item1High).add(item1High).copy,
        [item1High, item1High],
      );
      expect(
        Queue([]).add(item1High).add(item1Low).copy,
        [item1High, item1Low],
      );
      expect(
        Queue([]).add(item1Low).add(item1High).copy,
        [item1High, item1Low],
      );
    });
  });
}
