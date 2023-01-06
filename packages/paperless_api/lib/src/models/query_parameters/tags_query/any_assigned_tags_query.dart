import 'package:json_annotation/json_annotation.dart';

import 'tags_query.dart';
part 'any_assigned_tags_query.g.dart';

@JsonSerializable(explicitToJson: true)
class AnyAssignedTagsQuery extends TagsQuery {
  final Iterable<int> tagIds;

  const AnyAssignedTagsQuery({
    this.tagIds = const [],
  });

  @override
  Map<String, String> toQueryParameter() {
    if (tagIds.isEmpty) {
      return {'is_tagged': '1'};
    }
    return {'tags__id__in': tagIds.join(',')};
  }

  @override
  List<Object?> get props => [tagIds];

  @override
  Map<String, dynamic> toJson() => _$AnyAssignedTagsQueryToJson(this);

  factory AnyAssignedTagsQuery.fromJson(Map<String, dynamic> json) =>
      _$AnyAssignedTagsQueryFromJson(json);
}
