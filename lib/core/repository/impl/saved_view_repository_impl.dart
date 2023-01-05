import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/saved_view_repository.dart';
import 'package:rxdart/rxdart.dart';

class SavedViewRepositoryImpl implements SavedViewRepository {
  final PaperlessSavedViewsApi _api;

  SavedViewRepositoryImpl(this._api);

  final _subject = BehaviorSubject<Map<int, SavedView>?>();

  @override
  Stream<Map<int, SavedView>?> get values =>
      _subject.stream.asBroadcastStream();

  @override
  void clear() {
    _subject.add(const {});
  }

  @override
  Future<SavedView> create(SavedView view) async {
    final created = await _api.save(view);
    final updatedState = {..._subject.valueOrNull ?? {}}
      ..putIfAbsent(created.id!, () => created);
    _subject.add(updatedState);
    return created;
  }

  @override
  Future<int> delete(SavedView view) async {
    await _api.delete(view);
    final updatedState = {..._subject.valueOrNull ?? {}}..remove(view.id);
    _subject.add(updatedState);
    return view.id!;
  }

  @override
  Future<SavedView?> find(int id) async {
    final found = await _api.find(id);
    final updatedState = {..._subject.valueOrNull ?? {}}
      ..update(id, (_) => found, ifAbsent: () => found);
    _subject.add(updatedState);
    return found;
  }

  @override
  Future<Iterable<SavedView>> findAll([Iterable<int>? ids]) async {
    final found = await _api.findAll(ids);
    final updatedState = {
      ..._subject.valueOrNull ?? {},
      ...{for (final view in found) view.id!: view},
    };
    _subject.add(updatedState);
    return found;
  }

  @override
  Map<int, SavedView>? get current => _subject.valueOrNull;

  @override
  bool get isInitialized => _subject.hasValue;

  @override
  Future<SavedView> update(SavedView object) {
    throw UnimplementedError("Saved view update is not yet implemented");
  }
}
