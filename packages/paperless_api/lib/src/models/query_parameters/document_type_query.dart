import 'package:paperless_api/src/models/query_parameters/id_query_parameter.dart';

class DocumentTypeQuery extends IdQueryParameter {
  const DocumentTypeQuery.fromId(super.id) : super.fromId();
  const DocumentTypeQuery.unset() : super.unset();
  const DocumentTypeQuery.notAssigned() : super.notAssigned();
  const DocumentTypeQuery.anyAssigned() : super.anyAssigned();

  @override
  String get queryParameterKey => 'document_type';
}
