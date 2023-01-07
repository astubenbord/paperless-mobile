// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'correspondent_repository_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CorrespondentRepositoryState _$CorrespondentRepositoryStateFromJson(
        Map<String, dynamic> json) =>
    CorrespondentRepositoryState(
      values: (json['values'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(int.parse(k),
                Correspondent.fromJson(e as Map<String, dynamic>)),
          ) ??
          const {},
      hasLoaded: json['hasLoaded'] as bool? ?? false,
    );

Map<String, dynamic> _$CorrespondentRepositoryStateToJson(
        CorrespondentRepositoryState instance) =>
    <String, dynamic>{
      'values': instance.values.map((k, e) => MapEntry(k.toString(), e)),
      'hasLoaded': instance.hasLoaded,
    };
