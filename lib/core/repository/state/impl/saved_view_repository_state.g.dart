// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_view_repository_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SavedViewRepositoryState _$SavedViewRepositoryStateFromJson(
        Map<String, dynamic> json) =>
    SavedViewRepositoryState(
      values: (json['values'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
                int.parse(k), SavedView.fromJson(e as Map<String, dynamic>)),
          ) ??
          const {},
      hasLoaded: json['hasLoaded'] as bool? ?? false,
    );

Map<String, dynamic> _$SavedViewRepositoryStateToJson(
        SavedViewRepositoryState instance) =>
    <String, dynamic>{
      'values': instance.values.map((k, e) => MapEntry(k.toString(), e)),
      'hasLoaded': instance.hasLoaded,
    };
