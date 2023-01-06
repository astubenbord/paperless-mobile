// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'relative_date_range_query.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RelativeDateRangeQuery _$RelativeDateRangeQueryFromJson(
        Map<String, dynamic> json) =>
    RelativeDateRangeQuery(
      json['offset'] as int? ?? 1,
      $enumDecodeNullable(_$DateRangeUnitEnumMap, json['unit']) ??
          DateRangeUnit.day,
    );

Map<String, dynamic> _$RelativeDateRangeQueryToJson(
        RelativeDateRangeQuery instance) =>
    <String, dynamic>{
      'offset': instance.offset,
      'unit': _$DateRangeUnitEnumMap[instance.unit]!,
    };

const _$DateRangeUnitEnumMap = {
  DateRangeUnit.day: 'day',
  DateRangeUnit.week: 'week',
  DateRangeUnit.month: 'month',
  DateRangeUnit.year: 'year',
};
