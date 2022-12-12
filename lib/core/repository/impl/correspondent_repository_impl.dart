import 'dart:async';

import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:rxdart/rxdart.dart' show BehaviorSubject;

class CorrespondentRepositoryImpl implements LabelRepository<Correspondent> {
  final PaperlessLabelsApi _api;

  final _subject = BehaviorSubject<Map<int, Correspondent>>.seeded(const {});

  CorrespondentRepositoryImpl(this._api);
  @override
  Stream<Map<int, Correspondent>> get labels =>
      _subject.stream.asBroadcastStream();

  @override
  Future<Correspondent> create(Correspondent correspondent) async {
    final created = await _api.saveCorrespondent(correspondent);
    final updatedState = {..._subject.value}
      ..putIfAbsent(created.id!, () => created);
    _subject.add(updatedState);
    return created;
  }

  @override
  Future<void> delete(Correspondent correspondent) async {
    await _api.deleteCorrespondent(correspondent);
    final updatedState = {..._subject.value}
      ..removeWhere((k, v) => k == correspondent.id);
    _subject.add(updatedState);
  }

  @override
  Future<Correspondent?> find(int id) async {
    final correspondent = await _api.getCorrespondent(id);
    if (correspondent != null) {
      final updatedState = {..._subject.value}..[id] = correspondent;
      _subject.add(updatedState);
      return correspondent;
    }
    return null;
  }

  @override
  Future<Iterable<Correspondent>> findAll([Iterable<int>? ids]) async {
    final correspondents = await _api.getCorrespondents(ids);
    final updatedState = {..._subject.value}
      ..addEntries(correspondents.map((e) => MapEntry(e.id!, e)));
    _subject.add(updatedState);
    return correspondents;
  }

  @override
  Future<Correspondent> update(Correspondent correspondent) async {
    final updated = await _api.updateCorrespondent(correspondent);
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
  Map<int, Correspondent> get current => _subject.value;
}
