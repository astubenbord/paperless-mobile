import 'package:json_annotation/json_annotation.dart';

import 'exclude_tag_id_query.dart';
import 'include_tag_id_query.dart';
import 'tag_id_query.dart';
import 'tags_query.dart';

class IdsTagsQuery extends TagsQuery {
  final Iterable<TagIdQuery> _idQueries;

  const IdsTagsQuery([this._idQueries = const []]);

  IdsTagsQuery.included(Iterable<int> ids)
      : _idQueries = ids.map((id) => IncludeTagIdQuery(id));

  IdsTagsQuery.fromIds(Iterable<int> ids) : this.included(ids);

  IdsTagsQuery.excluded(Iterable<int> ids)
      : _idQueries = ids.map((id) => ExcludeTagIdQuery(id));

  IdsTagsQuery withIdQueriesAdded(Iterable<TagIdQuery> idQueries) {
    final intersection = idQueries
        .map((idQ) => idQ.id)
        .toSet()
        .intersection(_idQueries.map((idQ) => idQ.id).toSet());
    final res = IdsTagsQuery(
      [...withIdsRemoved(intersection).queries, ...idQueries],
    );
    return res;
  }

  IdsTagsQuery withIdsRemoved(Iterable<int> ids) {
    return IdsTagsQuery(
      _idQueries.where((idQuery) => !ids.contains(idQuery.id)),
    );
  }

  Iterable<TagIdQuery> get queries => _idQueries;

  Iterable<int> get includedIds {
    return _idQueries.whereType<IncludeTagIdQuery>().map((e) => e.id);
  }

  Iterable<int> get excludedIds {
    return _idQueries.whereType<ExcludeTagIdQuery>().map((e) => e.id);
  }

  ///
  /// Returns a new instance with the type of the given [id] toggled.
  /// E.g. if the provided [id] is currently registered as a [IncludeTagIdQuery],
  /// then the new isntance will contain a [ExcludeTagIdQuery] with given id.
  ///
  IdsTagsQuery withIdQueryToggled(int id) {
    return IdsTagsQuery(
      _idQueries.map((idQ) => idQ.id == id ? idQ.toggle() : idQ),
    );
  }

  Iterable<int> get ids => [...includedIds, ...excludedIds];

  @override
  Map<String, String> toQueryParameter() {
    final Map<String, String> params = {};
    if (includedIds.isNotEmpty) {
      params.putIfAbsent('tags__id__all', () => includedIds.join(','));
    }
    if (excludedIds.isNotEmpty) {
      params.putIfAbsent('tags__id__none', () => excludedIds.join(','));
    }
    return params;
  }

  @override
  List<Object?> get props => [_idQueries];

  @override
  Map<String, dynamic> toJson() {
    return {
      'queries': _idQueries.map((e) => e.toJson()).toList(),
    };
  }

  factory IdsTagsQuery.fromJson(Map<String, dynamic> json) {
    return IdsTagsQuery(
      (json['queries'] as List).map((e) => TagIdQuery.fromJson(e)),
    );
  }
}
