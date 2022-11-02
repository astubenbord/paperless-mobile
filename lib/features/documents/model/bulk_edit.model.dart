import 'package:paperless_mobile/core/type/json.dart';

class BulkEditAction {
  final List<int> documents;
  final String _method;
  final Map<String, dynamic> parameters;

  BulkEditAction.delete(this.documents)
      : _method = 'delete',
        parameters = {};

  JSON toJson() {
    return {
      'documents': documents,
      'method': _method,
      'parameters': parameters,
    };
  }
}
