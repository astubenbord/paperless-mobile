import 'package:equatable/equatable.dart';

import 'date_range_query_field.dart';

abstract class DateRangeQuery extends Equatable {
  const DateRangeQuery();
  Map<String, String> toQueryParameter(DateRangeQueryField field);

  Map<String, dynamic> toJson();
}
