import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/core/repository/state/impl/correspondent_repository_state.dart';
import 'package:paperless_mobile/core/repository/state/impl/tag_repository_state.dart';
import 'package:paperless_mobile/core/repository/state/repository_state.dart';

class TagRepositoryImpl extends LabelRepository<Tag, TagRepositoryState> {
  final PaperlessLabelsApi _api;

  TagRepositoryImpl(this._api) : super(const TagRepositoryState());

  @override
  Future<Tag> create(Tag object) async {
    final created = await _api.saveTag(object);
    final updatedState = {...state.values}
      ..putIfAbsent(created.id!, () => created);
    emit(TagRepositoryState(values: updatedState, hasLoaded: true));
    return created;
  }

  @override
  Future<int> delete(Tag tag) async {
    await _api.deleteTag(tag);
    final updatedState = {...state.values}..removeWhere((k, v) => k == tag.id);
    emit(TagRepositoryState(values: updatedState, hasLoaded: true));
    return tag.id!;
  }

  @override
  Future<Tag?> find(int id) async {
    final tag = await _api.getTag(id);
    if (tag != null) {
      final updatedState = {...state.values}..[id] = tag;
      emit(TagRepositoryState(values: updatedState, hasLoaded: true));
      return tag;
    }
    return null;
  }

  @override
  Future<Iterable<Tag>> findAll([Iterable<int>? ids]) async {
    final tags = await _api.getTags(ids);
    final updatedState = {...state.values}
      ..addEntries(tags.map((e) => MapEntry(e.id!, e)));
    emit(TagRepositoryState(values: updatedState, hasLoaded: true));
    return tags;
  }

  @override
  Future<Tag> update(Tag tag) async {
    final updated = await _api.updateTag(tag);
    final updatedState = {...state.values}..update(updated.id!, (_) => updated);
    emit(TagRepositoryState(values: updatedState, hasLoaded: true));
    return updated;
  }

  @override
  TagRepositoryState? fromJson(Map<String, dynamic> json) {
    return TagRepositoryState.fromJson(json);
  }

  @override
  Map<String, dynamic>? toJson(TagRepositoryState state) {
    return state.toJson();
  }
}
