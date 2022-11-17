import 'package:equatable/equatable.dart';
import 'package:paperless_mobile/extensions/dart_extensions.dart';

abstract class TagsQuery with EquatableMixin {
  const TagsQuery();
  String toQueryParameter();
}

class OnlyNotAssignedTagsQuery extends TagsQuery {
  const OnlyNotAssignedTagsQuery();
  @override
  List<Object?> get props => [];

  @override
  String toQueryParameter() {
    return '&is_tagged=0';
  }
}

class AnyAssignedTagsQuery extends TagsQuery {
  const AnyAssignedTagsQuery();
  @override
  List<Object?> get props => [];

  @override
  String toQueryParameter() {
    return '&is_tagged=1';
  }
}

class IdsTagsQuery extends TagsQuery {
  final Iterable<TagIdQuery> _idQueries;

  const IdsTagsQuery([this._idQueries = const []]);

  const IdsTagsQuery.unset() : _idQueries = const [];

  IdsTagsQuery.included(Iterable<int> ids)
      : _idQueries = ids.map((id) => IncludeTagIdQuery(id));

  IdsTagsQuery.fromIds(Iterable<int> ids) : this.included(ids);

  IdsTagsQuery.excluded(Iterable<int> ids)
      : _idQueries = ids.map((id) => ExcludeTagIdQuery(id));

  IdsTagsQuery withIdQueriesAdded(Iterable<TagIdQuery> idQueries) {
    final intersection = _idQueries
        .map((idQ) => idQ.id)
        .toSet()
        .intersection(_idQueries.map((idQ) => idQ.id).toSet());
    return IdsTagsQuery(
      [...withIdsRemoved(intersection).queries, ...idQueries],
    );
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

abstract class TagIdQuery with EquatableMixin {
  final int id;

  TagIdQuery(this.id);

  String get methodName;

  @override
  List<Object?> get props => [id, methodName];

  TagIdQuery toggle();
}

class IncludeTagIdQuery extends TagIdQuery {
  IncludeTagIdQuery(super.id);

  @override
  String get methodName => 'include';

  @override
  TagIdQuery toggle() {
    return ExcludeTagIdQuery(id);
  }
}

class ExcludeTagIdQuery extends TagIdQuery {
  ExcludeTagIdQuery(super.id);

  @override
  String get methodName => 'exclude';

  @override
  TagIdQuery toggle() {
    return IncludeTagIdQuery(id);
  }
}
