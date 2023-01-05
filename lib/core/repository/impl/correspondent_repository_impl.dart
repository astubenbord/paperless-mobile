import 'dart:async';

import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:rxdart/rxdart.dart' show BehaviorSubject;

class CorrespondentRepositoryImpl implements LabelRepository<Correspondent> {
  final PaperlessLabelsApi _api;

  final _subject = BehaviorSubject<Map<int, Correspondent>?>();

  CorrespondentRepositoryImpl(this._api);

  @override
  bool get isInitialized => _subject.valueOrNull != null;

  @override
  Stream<Map<int, Correspondent>?> get values =>
      _subject.stream.asBroadcastStream();

  Map<int, Correspondent> get _currentValueOrEmpty =>
      _subject.valueOrNull ?? {};

  @override
  Future<Correspondent> create(Correspondent correspondent) async {
    final created = await _api.saveCorrespondent(correspondent);
    final updatedState = {..._currentValueOrEmpty}
      ..putIfAbsent(created.id!, () => created);
    _subject.add(updatedState);
    return created;
  }

  @override
  Future<int> delete(Correspondent correspondent) async {
    await _api.deleteCorrespondent(correspondent);
    final updatedState = {..._currentValueOrEmpty}
      ..removeWhere((k, v) => k == correspondent.id);
    _subject.add(updatedState);
    return correspondent.id!;
  }

  @override
  Future<Correspondent?> find(int id) async {
    final correspondent = await _api.getCorrespondent(id);
    if (correspondent != null) {
      final updatedState = {..._currentValueOrEmpty}..[id] = correspondent;
      _subject.add(updatedState);
      return correspondent;
    }
    return null;
  }

  @override
  Future<Iterable<Correspondent>> findAll([Iterable<int>? ids]) async {
    final correspondents = await _api.getCorrespondents(ids);
    final updatedState = {..._currentValueOrEmpty}
      ..addEntries(correspondents.map((e) => MapEntry(e.id!, e)));
    _subject.add(updatedState);
    return correspondents;
  }

  @override
  Future<Correspondent> update(Correspondent correspondent) async {
    final updated = await _api.updateCorrespondent(correspondent);
    final updatedState = {..._currentValueOrEmpty}
      ..update(updated.id!, (_) => updated);
    _subject.add(updatedState);
    return updated;
  }

  @override
  void clear() {
    _subject.add(null);
  }

  @override
  Map<int, Correspondent>? get current => _subject.valueOrNull;
}
