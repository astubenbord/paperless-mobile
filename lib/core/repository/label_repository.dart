import 'package:paperless_api/paperless_api.dart';

abstract class LabelRepository<T extends Label> {
  Stream<Map<int, T>> get labels;

  Map<int, T> get current;

  Future<T> create(T label);
  Future<T?> find(int id);
  Future<Iterable<T>> findAll([Iterable<int>? ids]);
  Future<T> update(T label);
  Future<void> delete(T label);

  void clear();
}
