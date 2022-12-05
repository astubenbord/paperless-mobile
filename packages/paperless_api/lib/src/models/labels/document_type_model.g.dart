// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_type_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DocumentType _$DocumentTypeFromJson(Map<String, dynamic> json) => DocumentType(
      id: json['id'] as int?,
      name: json['name'] as String,
      slug: json['slug'] as String?,
      match: json['match'] as String?,
      matchingAlgorithm: $enumDecodeNullable(
          _$MatchingAlgorithmEnumMap, json['matching_algorithm']),
      isInsensitive: json['is_insensitive'] as bool?,
      documentCount: json['document_count'] as int?,
    );

Map<String, dynamic> _$DocumentTypeToJson(DocumentType instance) {
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
