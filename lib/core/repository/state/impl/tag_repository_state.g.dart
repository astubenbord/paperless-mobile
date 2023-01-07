// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_repository_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TagRepositoryState _$TagRepositoryStateFromJson(Map<String, dynamic> json) =>
    TagRepositoryState(
      values: (json['values'] as Map<String, dynamic>?)?.map(
            (k, e) =>
                MapEntry(int.parse(k), Tag.fromJson(e as Map<String, dynamic>)),
          ) ??
          const {},
      hasLoaded: json['hasLoaded'] as bool? ?? false,
    );

Map<String, dynamic> _$TagRepositoryStateToJson(TagRepositoryState instance) =>
    <String, dynamic>{
      'values': instance.values.map((k, e) => MapEntry(k.toString(), e)),
      'hasLoaded': instance.hasLoaded,
    };
