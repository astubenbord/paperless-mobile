import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:equatable/equatable.dart';
import 'package:jiffy/jiffy.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:paperless_api/src/constants/api_date_format.dart';
import 'package:paperless_api/src/converters/local_date_time_json_converter.dart';

part 'date_range_query.g.dart';

enum DateRangeUnit { day, week, month, year }

enum DateRangeQueryField { created, added, modified }

sealed class DateRangeQuery {
  const DateRangeQuery();

  String get type;
  Map<String, String> toQueryParameter(DateRangeQueryField field);
  Map<String, dynamic> toJson();
  factory DateRangeQuery.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    switch (type) {
      case 'UnsetDateRangeQuery':
        return const UnsetDateRangeQuery();
      case 'RelativeDateRangeQuery':
        return RelativeDateRangeQuery.fromJson(json);
      case 'AbsoluteDateRangeQuery':
        return AbsoluteDateRangeQuery.fromJson(json);
      case 'ExactDateQuery':
        return ExactDateQuery.fromJson(json);
      default:
        throw UnimplementedError('Unknown DateRangeQuery type: $type');
    }
  }
}

class UnsetDateRangeQuery extends DateRangeQuery {
  const UnsetDateRangeQuery();

  @override
  @JsonKey(includeToJson: true, includeFromJson: false, required: true)
  final type = 'UnsetDateRangeQuery';

  @override
  Map<String, String> toQueryParameter(DateRangeQueryField field) => const {};

  @override
  Map<String, dynamic> toJson() => {'type': type};
}

@CopyWith()
@JsonSerializable()
class RelativeDateRangeQuery extends DateRangeQuery with EquatableMixin {
  @JsonKey(includeToJson: true, includeFromJson: false)
  @override
  final type = 'RelativeDateRangeQuery';

  final int offset;
  final DateRangeUnit unit;

  const RelativeDateRangeQuery([
    this.offset = 1,
    this.unit = DateRangeUnit.day,
  ]);

  @override
  List<Object?> get props => [offset, unit];

  @override
  Map<String, String> toQueryParameter(DateRangeQueryField field) {
    return {'query': '${field.name}:[-$offset ${unit.name} to now]'};
  }

  /// Returns the datetime when subtracting the offset given the unit from now.
  DateTime get dateTime {
    switch (unit) {
      case DateRangeUnit.day:
        return Jiffy.now().subtract(days: offset).dateTime;
      case DateRangeUnit.week:
        return Jiffy.now().subtract(weeks: offset).dateTime;
      case DateRangeUnit.month:
        return Jiffy.now().subtract(months: offset).dateTime;
      case DateRangeUnit.year:
        return Jiffy.now().subtract(years: offset).dateTime;
    }
  }

  @override
  Map<String, dynamic> toJson() => _$RelativeDateRangeQueryToJson(this);
  factory RelativeDateRangeQuery.fromJson(Map<String, dynamic> json) =>
      _$RelativeDateRangeQueryFromJson(json);
}

@CopyWith()
@JsonSerializable()
class AbsoluteDateRangeQuery extends DateRangeQuery with EquatableMixin {
  @JsonKey(includeToJson: true, includeFromJson: true)
  @override
  final type = 'AbsoluteDateRangeQuery';

  @LocalDateTimeJsonConverter()
  final DateTime? after;

  @LocalDateTimeJsonConverter()
  final DateTime? before;

  const AbsoluteDateRangeQuery({this.after, this.before});

  @override
  List<Object?> get props => [after, before];

  @override
  Map<String, String> toQueryParameter(DateRangeQueryField field) {
    final Map<String, String> params = {};

    // Add/subtract one day in the following because paperless uses gt/lt not gte/lte
    if (after != null) {
      params.putIfAbsent(
        '${field.name}__date__gt',
        () => apiDateFormat.format(after!.subtract(const Duration(days: 1))),
      );
    }

    if (before != null) {
      params.putIfAbsent(
        '${field.name}__date__lt',
        () => apiDateFormat.format(before!.add(const Duration(days: 1))),
      );
    }
    return params;
  }

  @override
  Map<String, dynamic> toJson() => _$AbsoluteDateRangeQueryToJson(this);
  factory AbsoluteDateRangeQuery.fromJson(Map<String, dynamic> json) =>
      _$AbsoluteDateRangeQueryFromJson(json);
}

@CopyWith()
@JsonSerializable()
class ExactDateQuery extends DateRangeQuery with EquatableMixin {
  @JsonKey(includeToJson: true, includeFromJson: true)
  @override
  final type = 'ExactDateQuery';

  @LocalDateTimeJsonConverter()
  final DateTime date;

  const ExactDateQuery({required this.date});

  @override
  List<Object?> get props => [date];

  @override
  Map<String, String> toQueryParameter(DateRangeQueryField field) {
    return {
      '${field.name}__date__gt':
          apiDateFormat.format(date.subtract(const Duration(days: 1))),
      '${field.name}__date__lt':
          apiDateFormat.format(date.add(const Duration(days: 1))),
    };
  }

  @override
  Map<String, dynamic> toJson() => _$ExactDateQueryToJson(this);
  factory ExactDateQuery.fromJson(Map<String, dynamic> json) =>
      _$ExactDateQueryFromJson(json);
}
