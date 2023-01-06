import 'package:json_annotation/json_annotation.dart';

import 'date_range_query.dart';
import 'date_range_query_field.dart';
import 'date_range_unit.dart';
part 'relative_date_range_query.g.dart';

@JsonSerializable()
class RelativeDateRangeQuery extends DateRangeQuery {
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
    return {
      'query': '${field.name}:[-$offset ${unit.name} to now]',
    };
  }

  RelativeDateRangeQuery copyWith({
    int? offset,
    DateRangeUnit? unit,
  }) {
    return RelativeDateRangeQuery(
      offset ?? this.offset,
      unit ?? this.unit,
    );
  }

  @override
  Map<String, dynamic> toJson() => _$RelativeDateRangeQueryToJson(this);

  factory RelativeDateRangeQuery.fromJson(Map<String, dynamic> json) =>
      _$RelativeDateRangeQueryFromJson(json);
}
