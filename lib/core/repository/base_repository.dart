///
/// Base repository class which all repositories should implement
///
abstract class BaseRepository<State, Object> {
  Stream<State?> get values;

  State? get current;

  bool get isInitialized;

  Future<Object> create(Object object);
  Future<Object?> find(int id);
  Future<Iterable<Object>> findAll([Iterable<int>? ids]);
  Future<Object> update(Object object);
  Future<int> delete(Object object);

  void clear();
}
