import 'package:paperless_mobile/core/type/types.dart';

class BulkEditAction {
  final List<int> documents;
  final BulkEditActionMethod _method;
  final Map<String, dynamic> parameters;

  BulkEditAction.delete(this.documents)
      : _method = BulkEditActionMethod.delete,
        parameters = {};

  JSON toJson() {
    return {
      'documents': documents,
      'method': _method.name,
      'parameters': parameters,
    };
  }
}

enum BulkEditActionMethod {
  delete,
  edit;
}
