extension MapFromList<Element> on List<Element> {
  Map<Key, Element> toMap<Key>(
          MapEntry<Key, Element> Function(Element e) getEntry) =>
      Map.fromEntries(map(getEntry));

  Map<Key, Element> toMapWhereKey<Key>(Key Function(Element e) getKey) =>
      Map.fromEntries(map((e) => MapEntry(getKey(e), e)));
}

/// A method returns a human readable string representing a file _size
String formatFileSize(int size, [int round = 1]) {
  int divider = 1024;

  if (size < divider) {
    return "$size B";
  }

  if (size < divider * divider && size % divider == 0) {
    return "${(size / divider).toStringAsFixed(0)} KB";
  }

  if (size < divider * divider) {
    return "${(size / divider).toStringAsFixed(round)} KB";
  }

  if (size < divider * divider * divider && size % divider == 0) {
    return "${(size / (divider * divider)).toStringAsFixed(0)} MB";
  }

  if (size < divider * divider * divider) {
    return "${(size / divider / divider).toStringAsFixed(round)} MB";
  }

  if (size < divider * divider * divider * divider && size % divider == 0) {
    return "${(size / (divider * divider * divider)).toStringAsFixed(0)} GB";
  }

  if (size < divider * divider * divider * divider) {
    return "${(size / divider / divider / divider).toStringAsFixed(round)} GB";
  }

  if (size < divider * divider * divider * divider * divider &&
      size % divider == 0) {
    num r = size / divider / divider / divider / divider;
    return "${r.toStringAsFixed(0)} TB";
  }

  if (size < divider * divider * divider * divider * divider) {
    num r = size / divider / divider / divider / divider;
    return "${r.toStringAsFixed(round)} TB";
  }

  if (size < divider * divider * divider * divider * divider * divider &&
      size % divider == 0) {
    num r = size / divider / divider / divider / divider / divider;
    return "${r.toStringAsFixed(0)} PB";
  } else {
    num r = size / divider / divider / divider / divider / divider;
    return "${r.toStringAsFixed(round)} PB";
  }
}

// extension IterableExtension<E> on Iterable<E> {
//   E? findFirst(bool Function(E) test) {}
//
//   E? findLast(bool Function(E) test) {}
//
//   E? findSingle(bool Function(E) test) {}
// }

extension<T> on Stream<T> {
  // ignore: unused_element
  Future<T?> get firstWhereOrNull async {
    await for (var e in this) {
      return e;
    }
    return null;
  }
}
