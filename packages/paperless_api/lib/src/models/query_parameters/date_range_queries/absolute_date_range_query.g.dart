// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'absolute_date_range_query.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AbsoluteDateRangeQuery _$AbsoluteDateRangeQueryFromJson(
        Map<String, dynamic> json) =>
    AbsoluteDateRangeQuery(
      after: json['after'] == null
          ? null
          : DateTime.parse(json['after'] as String),
      before: json['before'] == null
          ? null
          : DateTime.parse(json['before'] as String),
    );

Map<String, dynamic> _$AbsoluteDateRangeQueryToJson(
        AbsoluteDateRangeQuery instance) =>
    <String, dynamic>{
      'after': instance.after?.toIso8601String(),
      'before': instance.before?.toIso8601String(),
    };
