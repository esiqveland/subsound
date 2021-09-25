import 'package:flutter/foundation.dart';
import 'package:subsound/components/player.dart';

enum QueuePriority {
  low,
  user,
}

class Queue {
  final int? _queuePosition;
  final List<QueueItem> _queue;

  Queue(this._queue, [this._queuePosition]);

  int get length => _queue.length;
  int? get position => _queuePosition;
  List<QueueItem> get toList => _queue.toList();

  Queue copy({
    List<QueueItem>? queue,
    int? nextPosition,
  }) =>
      Queue(
        queue ?? _queue,
        nextPosition ?? _queuePosition,
      );

  Queue setPosition(int? nextPosition) => Queue(_queue, nextPosition);

  Queue add(QueueItem item) => addAll([item]);

  Queue addAll(List<QueueItem> items) {
    final q = List.of(_queue);
    int startFromIndex = _queuePosition == null ? 0 : _queuePosition! + 1;

    for (var item in items) {
      final idx = q.indexWhere(
        (element) => item.priority.index > element.priority.index,
        startFromIndex,
      );
      if (idx == -1) {
        q.add(item);
      } else {
        q.insert(idx, item);
      }
    }

    return Queue(q, _queuePosition);
  }

  @override
  String toString() {
    return 'Queue{queuePosition: $_queuePosition, ${_queue.length}';
  }
}

class QueueItem {
  final PlayerSong song;
  final QueuePriority priority;

  QueueItem(this.song, this.priority);

  @override
  String toString() {
    return "QueueItem(${song.id}, ${describeEnum(priority)})";
  }
}
