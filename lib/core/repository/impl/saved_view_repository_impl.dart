import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/saved_view_repository.dart';
import 'package:paperless_mobile/core/repository/state/impl/saved_view_repository_state.dart';

class SavedViewRepositoryImpl extends SavedViewRepository {
  final PaperlessSavedViewsApi _api;

  SavedViewRepositoryImpl(this._api) : super(const SavedViewRepositoryState());

  @override
  Future<SavedView> create(SavedView view) async {
    final created = await _api.save(view);
    final updatedState = {...state.values}
      ..putIfAbsent(created.id!, () => created);
    emit(SavedViewRepositoryState(values: updatedState, hasLoaded: true));
    return created;
  }

  @override
  Future<int> delete(SavedView view) async {
    await _api.delete(view);
    final updatedState = {...state.values}..remove(view.id);
    emit(SavedViewRepositoryState(values: updatedState, hasLoaded: true));
    return view.id!;
  }

  @override
  Future<SavedView?> find(int id) async {
    final found = await _api.find(id);
    final updatedState = {...state.values}
      ..update(id, (_) => found, ifAbsent: () => found);
    emit(SavedViewRepositoryState(values: updatedState, hasLoaded: true));
    return found;
  }

  @override
  Future<Iterable<SavedView>> findAll([Iterable<int>? ids]) async {
    final found = await _api.findAll(ids);
    final updatedState = {
      ...state.values,
      ...{for (final view in found) view.id!: view},
    };
    emit(SavedViewRepositoryState(values: updatedState, hasLoaded: true));
    return found;
  }

  @override
  Future<SavedView> update(SavedView object) {
    throw UnimplementedError(
        "Saved view update is not yet implemented as it is not supported by the API.");
  }

  @override
  SavedViewRepositoryState fromJson(Map<String, dynamic> json) {
    return SavedViewRepositoryState.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(SavedViewRepositoryState state) {
    return state.toJson();
  }
}
