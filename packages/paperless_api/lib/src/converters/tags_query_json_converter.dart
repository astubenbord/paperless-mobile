import 'package:json_annotation/json_annotation.dart';
import 'package:paperless_api/src/models/query_parameters/tags_query/any_assigned_tags_query.dart';
import 'package:paperless_api/src/models/query_parameters/tags_query/ids_tags_query.dart';
import 'package:paperless_api/src/models/query_parameters/tags_query/only_not_assigned_tags_query.dart';

import '../models/query_parameters/tags_query/tags_query.dart';

class TagsQueryJsonConverter
    extends JsonConverter<TagsQuery, Map<String, dynamic>> {
  const TagsQueryJsonConverter();
  @override
  TagsQuery fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final data = json['data'] as Map<String, dynamic>;
    switch (type) {
      case 'OnlyNotAssignedTagsQuery':
        return const OnlyNotAssignedTagsQuery();
      case 'AnyAssignedTagsQuery':
        return AnyAssignedTagsQuery.fromJson(data);
      case 'IdsTagsQuery':
        return IdsTagsQuery.fromJson(data);
      default:
        throw Exception('Error parsing TagsQuery: Unknown type $type');
    }
  }

  @override
  Map<String, dynamic> toJson(TagsQuery object) {
    return {
      'type': object.runtimeType.toString(),
      'data': object.toJson(),
    };
  }
}
