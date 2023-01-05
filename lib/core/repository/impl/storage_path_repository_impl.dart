import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:rxdart/rxdart.dart' show BehaviorSubject;

class StoragePathRepositoryImpl implements LabelRepository<StoragePath> {
  final PaperlessLabelsApi _api;

  final _subject = BehaviorSubject<Map<int, StoragePath>?>();

  StoragePathRepositoryImpl(this._api);

  @override
  Stream<Map<int, StoragePath>?> get values =>
      _subject.stream.asBroadcastStream();

  Map<int, StoragePath> get _currentValueOrEmpty => _subject.valueOrNull ?? {};

  @override
  Future<StoragePath> create(StoragePath storagePath) async {
    final created = await _api.saveStoragePath(storagePath);
    final updatedState = {..._currentValueOrEmpty}
      ..putIfAbsent(created.id!, () => created);
    _subject.add(updatedState);
    return created;
  }

  @override
  Future<int> delete(StoragePath storagePath) async {
    await _api.deleteStoragePath(storagePath);
    final updatedState = {..._currentValueOrEmpty}
      ..removeWhere((k, v) => k == storagePath.id);
    _subject.add(updatedState);
    return storagePath.id!;
  }

  @override
  Future<StoragePath?> find(int id) async {
    final storagePath = await _api.getStoragePath(id);
    if (storagePath != null) {
      final updatedState = {..._currentValueOrEmpty}..[id] = storagePath;
      _subject.add(updatedState);
      return storagePath;
    }
    return null;
  }

  @override
  Future<Iterable<StoragePath>> findAll([Iterable<int>? ids]) async {
    final storagePaths = await _api.getStoragePaths(ids);
    final updatedState = {..._currentValueOrEmpty}
      ..addEntries(storagePaths.map((e) => MapEntry(e.id!, e)));
    _subject.add(updatedState);
    return storagePaths;
  }

  @override
  Future<StoragePath> update(StoragePath storagePath) async {
    final updated = await _api.updateStoragePath(storagePath);
    final updatedState = {..._currentValueOrEmpty}
      ..update(updated.id!, (_) => updated);
    _subject.add(updatedState);
    return updated;
  }

  @override
  void clear() {
    _subject.add(const {});
  }

  @override
  Map<int, StoragePath>? get current => _subject.valueOrNull;

  @override
  bool get isInitialized => _subject.valueOrNull != null;
}
