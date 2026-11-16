import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'queryParam')
enum QueryType {
  title('title__icontains'),
  titleSearch('title_search'),
  titleAndContent('title_content'),
  simpleText('text'),
  extended('query'),
  asn('asn');

  final String queryParam;
  const QueryType(this.queryParam);
}
