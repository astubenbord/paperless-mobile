import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:rxdart/rxdart.dart' show BehaviorSubject;

class StoragePathRepositoryImpl implements LabelRepository<StoragePath> {
  final PaperlessLabelsApi _api;

  final _subject = BehaviorSubject<Map<int, StoragePath>>.seeded(const {});

  StoragePathRepositoryImpl(this._api);

  @override
  Stream<Map<int, StoragePath>> get labels =>
      _subject.stream.asBroadcastStream();

  @override
  Future<StoragePath> create(StoragePath storagePath) async {
    final created = await _api.saveStoragePath(storagePath);
    final updatedState = {..._subject.value}
      ..putIfAbsent(created.id!, () => created);
    _subject.add(updatedState);
    return created;
  }

  @override
  Future<void> delete(StoragePath storagePath) async {
    await _api.deleteStoragePath(storagePath);
    final updatedState = {..._subject.value}
      ..removeWhere((k, v) => k == storagePath.id);
    _subject.add(updatedState);
  }

  @override
  Future<StoragePath?> find(int id) async {
    final storagePath = await _api.getStoragePath(id);
    if (storagePath != null) {
      final updatedState = {..._subject.value}..[id] = storagePath;
      _subject.add(updatedState);
      return storagePath;
    }
    return null;
  }

  @override
  Future<Iterable<StoragePath>> findAll([Iterable<int>? ids]) async {
    final storagePaths = await _api.getStoragePaths(ids);
    final updatedState = {..._subject.value}
      ..addEntries(storagePaths.map((e) => MapEntry(e.id!, e)));
    _subject.add(updatedState);
    return storagePaths;
  }

  @override
  Future<StoragePath> update(StoragePath storagePath) async {
    final updated = await _api.updateStoragePath(storagePath);
    final updatedState = {..._subject.value}
      ..update(updated.id!, (_) => updated);
    _subject.add(updatedState);
    return updated;
  }

  @override
  void clear() {
    _subject.add(const {});
  }

  @override
  Map<int, StoragePath> get current => _subject.value;
}
