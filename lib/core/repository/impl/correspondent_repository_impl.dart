import 'dart:async';

import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/core/repository/state/impl/correspondent_repository_state.dart';
import 'package:paperless_mobile/core/repository/state/repository_state.dart';

class CorrespondentRepositoryImpl
    extends LabelRepository<Correspondent, CorrespondentRepositoryState> {
  final PaperlessLabelsApi _api;

  CorrespondentRepositoryImpl(this._api)
      : super(const CorrespondentRepositoryState());

  @override
  Future<Correspondent> create(Correspondent correspondent) async {
    final created = await _api.saveCorrespondent(correspondent);
    final updatedState = {...state.values}
      ..putIfAbsent(created.id!, () => created);
    emit(CorrespondentRepositoryState(values: updatedState, hasLoaded: true));
    return created;
  }

  @override
  Future<int> delete(Correspondent correspondent) async {
    await _api.deleteCorrespondent(correspondent);
    final updatedState = {...state.values}
      ..removeWhere((k, v) => k == correspondent.id);
    emit(CorrespondentRepositoryState(values: updatedState, hasLoaded: true));
    return correspondent.id!;
  }

  @override
  Future<Correspondent?> find(int id) async {
    final correspondent = await _api.getCorrespondent(id);
    if (correspondent != null) {
      final updatedState = {...state.values}..[id] = correspondent;
      emit(CorrespondentRepositoryState(values: updatedState, hasLoaded: true));
      return correspondent;
    }
    return null;
  }

  @override
  Future<Iterable<Correspondent>> findAll([Iterable<int>? ids]) async {
    final correspondents = await _api.getCorrespondents(ids);
    final updatedState = {...state.values}
      ..addEntries(correspondents.map((e) => MapEntry(e.id!, e)));
    emit(CorrespondentRepositoryState(values: updatedState, hasLoaded: true));
    return correspondents;
  }

  @override
  Future<Correspondent> update(Correspondent correspondent) async {
    final updated = await _api.updateCorrespondent(correspondent);
    final updatedState = {...state.values}..update(updated.id!, (_) => updated);
    emit(CorrespondentRepositoryState(values: updatedState, hasLoaded: true));
    return updated;
  }

  @override
  CorrespondentRepositoryState fromJson(Map<String, dynamic> json) {
    return CorrespondentRepositoryState.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(CorrespondentRepositoryState state) {
    return state.toJson();
  }
}
