import 'package:flutter_paperless_mobile/features/documents/model/query_parameters/id_query_parameter.dart';

class AsnQuery extends IdQueryParameter {
  const AsnQuery.fromId(super.id) : super.fromId();
  const AsnQuery.unset() : super.unset();
  const AsnQuery.notAssigned() : super.notAssigned();

  @override
  String get queryParameterKey => 'archive_serial_number';
}
