import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/core/repository/state/impl/storage_path_repository_state.dart';
import 'package:rxdart/rxdart.dart' show BehaviorSubject;

class StoragePathRepositoryImpl
    extends LabelRepository<StoragePath, StoragePathRepositoryState> {
  final PaperlessLabelsApi _api;

  StoragePathRepositoryImpl(this._api)
      : super(const StoragePathRepositoryState());

  @override
  Future<StoragePath> create(StoragePath storagePath) async {
    final created = await _api.saveStoragePath(storagePath);
    final updatedState = {...state.values}
      ..putIfAbsent(created.id!, () => created);
    emit(StoragePathRepositoryState(values: updatedState, hasLoaded: true));
    return created;
  }

  @override
  Future<int> delete(StoragePath storagePath) async {
    await _api.deleteStoragePath(storagePath);
    final updatedState = {...state.values}
      ..removeWhere((k, v) => k == storagePath.id);
    emit(StoragePathRepositoryState(values: updatedState, hasLoaded: true));
    return storagePath.id!;
  }

  @override
  Future<StoragePath?> find(int id) async {
    final storagePath = await _api.getStoragePath(id);
    if (storagePath != null) {
      final updatedState = {...state.values}..[id] = storagePath;
      emit(StoragePathRepositoryState(values: updatedState, hasLoaded: true));
      return storagePath;
    }
    return null;
  }

  @override
  Future<Iterable<StoragePath>> findAll([Iterable<int>? ids]) async {
    final storagePaths = await _api.getStoragePaths(ids);
    final updatedState = {...state.values}
      ..addEntries(storagePaths.map((e) => MapEntry(e.id!, e)));
    emit(StoragePathRepositoryState(values: updatedState, hasLoaded: true));
    return storagePaths;
  }

  @override
  Future<StoragePath> update(StoragePath storagePath) async {
    final updated = await _api.updateStoragePath(storagePath);
    final updatedState = {...state.values}..update(updated.id!, (_) => updated);
    emit(StoragePathRepositoryState(values: updatedState, hasLoaded: true));
    return updated;
  }

  @override
  StoragePathRepositoryState fromJson(Map<String, dynamic> json) {
    return StoragePathRepositoryState.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(StoragePathRepositoryState state) {
    return state.toJson();
  }
}
