import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum SortOrder {
  ascending(""),
  descending("-");

  final String queryString;
  const SortOrder(this.queryString);

  SortOrder toggle() {
    return this == ascending ? descending : ascending;
  }
}
