// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_type_repository_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DocumentTypeRepositoryState _$DocumentTypeRepositoryStateFromJson(
        Map<String, dynamic> json) =>
    DocumentTypeRepositoryState(
      values: (json['values'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
                int.parse(k), DocumentType.fromJson(e as Map<String, dynamic>)),
          ) ??
          const {},
      hasLoaded: json['hasLoaded'] as bool? ?? false,
    );

Map<String, dynamic> _$DocumentTypeRepositoryStateToJson(
        DocumentTypeRepositoryState instance) =>
    <String, dynamic>{
      'values': instance.values.map((k, e) => MapEntry(k.toString(), e)),
      'hasLoaded': instance.hasLoaded,
    };
