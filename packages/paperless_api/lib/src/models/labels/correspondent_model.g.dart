// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'correspondent_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Correspondent _$CorrespondentFromJson(Map<String, dynamic> json) =>
    Correspondent(
      id: json['id'] as int?,
      name: json['name'] as String,
      slug: json['slug'] as String?,
      match: json['match'] as String?,
      matchingAlgorithm: $enumDecodeNullable(
          _$MatchingAlgorithmEnumMap, json['matching_algorithm']),
      isInsensitive: json['is_insensitive'] as bool?,
      documentCount: json['document_count'] as int?,
      lastCorrespondence: json['last_correspondence'] == null
          ? null
          : DateTime.parse(json['last_correspondence'] as String),
    );

Map<String, dynamic> _$CorrespondentToJson(Correspondent instance) {
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
  writeNotNull(
      'last_correspondence', instance.lastCorrespondence?.toIso8601String());
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
