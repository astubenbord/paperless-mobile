// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'any_assigned_tags_query.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnyAssignedTagsQuery _$AnyAssignedTagsQueryFromJson(
        Map<String, dynamic> json) =>
    AnyAssignedTagsQuery(
      tagIds:
          (json['tagIds'] as List<dynamic>?)?.map((e) => e as int) ?? const [],
    );

Map<String, dynamic> _$AnyAssignedTagsQueryToJson(
        AnyAssignedTagsQuery instance) =>
    <String, dynamic>{
      'tagIds': instance.tagIds.toList(),
    };
