import 'package:equatable/equatable.dart';

abstract class TagsQuery extends Equatable {
  const TagsQuery();
  String toQueryParameter();
}

class OnlyNotAssignedTagsQuery extends TagsQuery {
  const OnlyNotAssignedTagsQuery();
  @override
  String toQueryParameter() {
    return '&is_tagged=0';
  }

  @override
  List<Object?> get props => [];
}

class AnyAssignedTagsQuery extends TagsQuery {
  final Iterable<int> tagIds;

  const AnyAssignedTagsQuery({
    this.tagIds = const [],
  });

  @override
  String toQueryParameter() {
    if (tagIds.isEmpty) {
      return '&is_tagged=1';
    }
    return '&tags__id__in=${tagIds.join(',')}';
  }

  @override
  List<Object?> get props => [tagIds];
}

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
  String toQueryParameter() {
    final StringBuffer sb = StringBuffer("");
    if (includedIds.isNotEmpty) {
      sb.write('&tags__id__all=${includedIds.join(',')}');
    }
    if (excludedIds.isNotEmpty) {
      sb.write('&tags__id__none=${excludedIds.join(',')}');
    }
    return sb.toString();
  }

  @override
  List<Object?> get props => [_idQueries];
}

abstract class TagIdQuery extends Equatable {
  final int id;

  const TagIdQuery(this.id);

  String get methodName;

  @override
  List<Object?> get props => [id, methodName];

  TagIdQuery toggle();
}

class IncludeTagIdQuery extends TagIdQuery {
  const IncludeTagIdQuery(super.id);

  @override
  String get methodName => 'include';

  @override
  TagIdQuery toggle() {
    return ExcludeTagIdQuery(id);
  }
}

class ExcludeTagIdQuery extends TagIdQuery {
  const ExcludeTagIdQuery(super.id);

  @override
  String get methodName => 'exclude';

  @override
  TagIdQuery toggle() {
    return IncludeTagIdQuery(id);
  }
}
