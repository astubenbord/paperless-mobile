import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:rxdart/rxdart.dart' show BehaviorSubject;

class TagRepositoryImpl implements LabelRepository<Tag> {
  final PaperlessLabelsApi _api;

  final _subject = BehaviorSubject<Map<int, Tag>?>();

  TagRepositoryImpl(this._api);

  @override
  Stream<Map<int, Tag>?> get values => _subject.stream.asBroadcastStream();

  Map<int, Tag> get _currentValueOrEmpty => _subject.valueOrNull ?? {};

  @override
  Future<Tag> create(Tag tag) async {
    final created = await _api.saveTag(tag);
    final updatedState = {..._currentValueOrEmpty}
      ..putIfAbsent(created.id!, () => created);
    _subject.add(updatedState);
    return created;
  }

  @override
  Future<int> delete(Tag tag) async {
    await _api.deleteTag(tag);
    final updatedState = {..._currentValueOrEmpty}
      ..removeWhere((k, v) => k == tag.id);
    _subject.add(updatedState);
    return tag.id!;
  }

  @override
  Future<Tag?> find(int id) async {
    final tag = await _api.getTag(id);
    if (tag != null) {
      final updatedState = {..._currentValueOrEmpty}..[id] = tag;
      _subject.add(updatedState);
      return tag;
    }
    return null;
  }

  @override
  Future<Iterable<Tag>> findAll([Iterable<int>? ids]) async {
    final tags = await _api.getTags(ids);
    final updatedState = {..._currentValueOrEmpty}
      ..addEntries(tags.map((e) => MapEntry(e.id!, e)));
    _subject.add(updatedState);
    return tags;
  }

  @override
  Future<Tag> update(Tag tag) async {
    final updated = await _api.updateTag(tag);
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
  Map<int, Tag>? get current => _subject.valueOrNull;

  @override
  bool get isInitialized => _subject.valueOrNull != null;
}
