// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'field_suggestions.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FieldSuggestions _$FieldSuggestionsFromJson(Map<String, dynamic> json) =>
    FieldSuggestions(
      correspondents:
          (json['correspondents'] as List<dynamic>?)?.map((e) => e as int) ??
              const [],
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as int) ?? const [],
      documentTypes:
          (json['document_types'] as List<dynamic>?)?.map((e) => e as int) ??
              const [],
      storagePaths:
          (json['storage_paths'] as List<dynamic>?)?.map((e) => e as int) ??
              const [],
      dates: (json['dates'] as List<dynamic>?)
              ?.map((e) => DateTime.parse(e as String)) ??
          const [],
    );

Map<String, dynamic> _$FieldSuggestionsToJson(FieldSuggestions instance) =>
    <String, dynamic>{
      'correspondents': instance.correspondents.toList(),
      'tags': instance.tags.toList(),
      'document_types': instance.documentTypes.toList(),
      'storage_paths': instance.storagePaths.toList(),
      'dates': instance.dates.map((e) => e.toIso8601String()).toList(),
    };
