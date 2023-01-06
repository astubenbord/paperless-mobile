import 'package:json_annotation/json_annotation.dart';
import 'package:paperless_api/src/constants.dart';

import 'date_range_query.dart';
import 'date_range_query_field.dart';

part 'absolute_date_range_query.g.dart';

@JsonSerializable()
class AbsoluteDateRangeQuery extends DateRangeQuery {
  final DateTime? after;
  final DateTime? before;

  const AbsoluteDateRangeQuery({this.after, this.before});

  @override
  List<Object?> get props => [after, before];

  @override
  Map<String, String> toQueryParameter(DateRangeQueryField field) {
    final Map<String, String> params = {};

    // Add/subtract one day in the following because paperless uses gt/lt not gte/lte
    if (after != null) {
      params.putIfAbsent('${field.name}__date__gt',
          () => apiDateFormat.format(after!.subtract(const Duration(days: 1))));
    }

    if (before != null) {
      params.putIfAbsent('${field.name}__date__lt',
          () => apiDateFormat.format(before!.add(const Duration(days: 1))));
    }
    return params;
  }

  AbsoluteDateRangeQuery copyWith({
    DateTime? before,
    DateTime? after,
  }) {
    return AbsoluteDateRangeQuery(
      before: before ?? this.before,
      after: after ?? this.after,
    );
  }

  factory AbsoluteDateRangeQuery.fromJson(json) =>
      _$AbsoluteDateRangeQueryFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$AbsoluteDateRangeQueryToJson(this);
}
