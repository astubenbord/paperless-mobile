import 'package:paperless_api/src/models/query_parameters/date_range_queries/date_range_query_field.dart';

import 'date_range_query.dart';

class UnsetDateRangeQuery extends DateRangeQuery {
  const UnsetDateRangeQuery();
  @override
  List<Object?> get props => [];

  @override
  Map<String, String> toQueryParameter(DateRangeQueryField field) => const {};

  @override
  Map<String, dynamic> toJson() {
    return {};
  }
}
