import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

import 'query_type.dart';

part 'text_query.g.dart';

@CopyWith()
@JsonSerializable()
class TextQuery {
  final QueryType queryType;
  final String? queryText;

  const TextQuery({this.queryType = QueryType.titleAndContent, this.queryText});
  const TextQuery.title(this.queryText) : queryType = QueryType.title;
  const TextQuery.titleSearch(this.queryText)
    : queryType = QueryType.titleSearch;
  const TextQuery.titleAndContent(this.queryText)
    : queryType = QueryType.titleAndContent;
  const TextQuery.simpleText(this.queryText) : queryType = QueryType.simpleText;
  const TextQuery.extended(this.queryText) : queryType = QueryType.extended;

  Map<String, String> toQueryParameter() {
    final params = <String, String>{};
    if (queryText != null && queryText!.isNotEmpty) {
      params.addAll({queryType.queryParam: queryText!});
    }
    return params;
  }

  String? get titleOnlyMatchString {
    if (queryType == QueryType.title || queryType == QueryType.titleSearch) {
      return queryText?.isEmpty ?? true ? null : queryText;
    }
    return null;
  }

  String? get titleAndContentMatchString {
    if (queryType == QueryType.titleAndContent ||
        queryType == QueryType.simpleText) {
      return queryText?.isEmpty ?? true ? null : queryText;
    }
    return null;
  }

  String? get extendedMatchString {
    if (queryType == QueryType.extended) {
      return queryText?.isEmpty ?? true ? null : queryText;
    }
    return null;
  }

  bool matches({required String title, String? content, int? asn}) {
    if (queryText?.isEmpty ?? true) return true;
    switch (queryType) {
      case QueryType.title:
      case QueryType.titleSearch:
        return title.contains(queryText!);
      case QueryType.titleAndContent:
      case QueryType.simpleText:
        return title.contains(queryText!) ||
            (content?.contains(queryText!) ?? false);
      case QueryType.extended:
        //TODO: Implement. Might be too complex...
        return true;
      case QueryType.asn:
        return int.tryParse(queryText!) == asn;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TextQuery) return false;
    if (queryText == null && other.queryText == null) {
      return true;
    }
    return other.queryText == queryText && other.queryType == queryType;
  }

  @override
  String toString() {
    return "TextQuery($queryText, $queryType)";
  }

  @override
  int get hashCode => Object.hash(queryText, queryType);

  Map<String, dynamic> toJson() => _$TextQueryToJson(this);
  factory TextQuery.fromJson(Map<String, dynamic> json) =>
      _$TextQueryFromJson(json);
}
