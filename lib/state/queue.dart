import 'package:subsound/components/player.dart';

enum QueuePriority {
  low,
  user,
}

class Queue {
  final List<QueueItem> _queue;

  Queue(this._queue);

  int get length => _queue.length;
  List<QueueItem> get copy => _queue.toList();

  Queue add(QueueItem item) => addAll([item]);

  Queue replaceWith(List<QueueItem> items) => Queue(
      List.of(items)..sort((a, b) => b.priority.index - a.priority.index));

  Queue addAll(List<QueueItem> items) {
    final q = List.of(_queue);
    items.forEach((item) {
      final idx = q.indexWhere(
          (element) => item.priority.index > element.priority.index);
      if (idx == -1) {
        q.add(item);
      } else {
        q.insert(idx, item);
      }
    });

    return Queue(q);
  }
}

class QueueItem {
  final PlayerSong song;
  final QueuePriority priority;

  QueueItem(this.song, this.priority);
}
