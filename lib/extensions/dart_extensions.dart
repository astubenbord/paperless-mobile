extension NullableMapKey<K, V> on Map<K, V> {
  V? tryPutIfAbsent(K key, V? Function() ifAbsent) {
    final value = ifAbsent();
    if (value == null) {
      return null;
    }
    return putIfAbsent(key, () => value);
  }
}

extension Unique<E, Id> on List<E> {
  List<E> unique([Id Function(E element)? id, bool inplace = true]) {
    final ids = <Id>{};
    var list = inplace ? this : List<E>.from(this);
    list.retainWhere((x) => ids.add(id != null ? id(x) : x as Id));
    return list;
  }
}

extension DuplicateCheckable<T> on Iterable<T> {
  bool hasDuplicates() {
    return toSet().length != length;
  }
}
