// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage_path_repository_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StoragePathRepositoryState _$StoragePathRepositoryStateFromJson(
        Map<String, dynamic> json) =>
    StoragePathRepositoryState(
      values: (json['values'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
                int.parse(k), StoragePath.fromJson(e as Map<String, dynamic>)),
          ) ??
          const {},
      hasLoaded: json['hasLoaded'] as bool? ?? false,
    );

Map<String, dynamic> _$StoragePathRepositoryStateToJson(
        StoragePathRepositoryState instance) =>
    <String, dynamic>{
      'values': instance.values.map((k, e) => MapEntry(k.toString(), e)),
      'hasLoaded': instance.hasLoaded,
    };
