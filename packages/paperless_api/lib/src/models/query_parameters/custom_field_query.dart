import 'dart:convert';

class CustomFieldQueryClause {
  final int fieldId;
  final String operator;
  final dynamic value;

  const CustomFieldQueryClause({
    required this.fieldId,
    required this.operator,
    required this.value,
  });

  List<dynamic> toJsonList() => [fieldId, operator, value];

  /// Encodes a list of clauses into a single custom_field_query parameter value.
  /// A single clause becomes `[fieldId, operator, value]`.
  /// Multiple clauses are wrapped as `["AND", [clause1, clause2, ...]]`.
  static String encodeAll(List<CustomFieldQueryClause> clauses) {
    if (clauses.length == 1) {
      return jsonEncode(clauses.first.toJsonList());
    }
    return jsonEncode([
      'AND',
      clauses.map((c) => c.toJsonList()).toList(),
    ]);
  }
}
