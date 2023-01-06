import 'package:json_annotation/json_annotation.dart';
import 'package:paperless_api/src/models/models.dart';
import 'package:paperless_api/src/models/query_parameters/date_range_queries/absolute_date_range_query.dart';
import 'package:paperless_api/src/models/query_parameters/date_range_queries/relative_date_range_query.dart';

class DateRangeQueryJsonConverter
    extends JsonConverter<DateRangeQuery, Map<String, dynamic>> {
  const DateRangeQueryJsonConverter();
  @override
  DateRangeQuery fromJson(Map<String, dynamic> json) {
    final type = json['type'];
    final data = json['data'];
    switch (json['type'] as String) {
      case 'UnsetDateRangeQuery':
        return const UnsetDateRangeQuery();
      case 'AbsoluteDateRangeQuery':
        return AbsoluteDateRangeQuery.fromJson(data);
      case 'RelativeDateRangeQuery':
        return RelativeDateRangeQuery.fromJson(data);
      default:
        throw Exception('Error parsing DateRangeQuery: Unknown type $type');
    }
  }

  @override
  Map<String, dynamic> toJson(DateRangeQuery object) {
    return {
      'type': object.runtimeType.toString(),
      'data': object.toJson(),
    };
  }
}
