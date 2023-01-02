import 'query_type.dart';

class TextQuery {
  final QueryType queryType;
  final String? queryText;

  const TextQuery({
    this.queryType = QueryType.titleAndContent,
    this.queryText,
  });

  const TextQuery.title(this.queryText) : queryType = QueryType.title;

  const TextQuery.titleAndContent(this.queryText)
      : queryType = QueryType.titleAndContent;

  const TextQuery.extended(this.queryText) : queryType = QueryType.extended;

  TextQuery copyWith({QueryType? queryType, String? queryText}) {
    return TextQuery(
      queryType: queryType ?? this.queryType,
      queryText: queryText ?? this.queryText,
    );
  }

  Map<String, String> toQueryParameter() {
    final params = <String, String>{};
    if (queryText != null) {
      params.addAll({queryType.queryParam: queryText!});
    }
    return params;
  }

  String? get titleOnlyMatchString {
    if (queryType == QueryType.title) {
      return queryText?.isEmpty ?? true ? null : queryText;
    }
    return null;
  }

  String? get titleAndContentMatchString {
    if (queryType == QueryType.titleAndContent) {
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
}
