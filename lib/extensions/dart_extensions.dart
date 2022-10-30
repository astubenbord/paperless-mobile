extension NullableMapKey<K, V> on Map<K, V> {
  V? tryPutIfAbsent(K key, V? Function() ifAbsent) {
    final value = ifAbsent();
    if (value == null) {
      return null;
    }
    return putIfAbsent(key, () => value);
  }
}
