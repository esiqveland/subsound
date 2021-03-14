extension MapFromList<Element> on List<Element> {
  Map<Key, Element> toMap<Key>(
          MapEntry<Key, Element> Function(Element e) getEntry) =>
      Map.fromEntries(map(getEntry));

  Map<Key, Element> toMapWhereKey<Key>(Key Function(Element e) getKey) =>
      Map.fromEntries(map((e) => MapEntry(getKey(e), e)));
}
