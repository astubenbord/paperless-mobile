// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage_path_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StoragePath _$StoragePathFromJson(Map<String, dynamic> json) => StoragePath(
      id: json['id'] as int?,
      name: json['name'] as String,
      slug: json['slug'] as String?,
      match: json['match'] as String?,
      matchingAlgorithm: $enumDecodeNullable(
          _$MatchingAlgorithmEnumMap, json['matching_algorithm']),
      isInsensitive: json['is_insensitive'] as bool?,
      documentCount: json['document_count'] as int?,
      path: json['path'] as String?,
    );

Map<String, dynamic> _$StoragePathToJson(StoragePath instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('id', instance.id);
  val['name'] = instance.name;
  writeNotNull('slug', instance.slug);
  writeNotNull('match', instance.match);
  writeNotNull('matching_algorithm',
      _$MatchingAlgorithmEnumMap[instance.matchingAlgorithm]);
  writeNotNull('is_insensitive', instance.isInsensitive);
  writeNotNull('document_count', instance.documentCount);
  writeNotNull('path', instance.path);
  return val;
}

const _$MatchingAlgorithmEnumMap = {
  MatchingAlgorithm.anyWord: 1,
  MatchingAlgorithm.allWords: 2,
  MatchingAlgorithm.exactMatch: 3,
  MatchingAlgorithm.regex: 4,
  MatchingAlgorithm.similarWord: 5,
  MatchingAlgorithm.auto: 6,
};
