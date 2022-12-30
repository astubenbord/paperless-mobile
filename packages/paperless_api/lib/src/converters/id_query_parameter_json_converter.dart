import 'package:json_annotation/json_annotation.dart';
import 'package:paperless_api/src/models/models.dart';

class IdQueryParameterJsonConverter
    extends JsonConverter<IdQueryParameter, Map<String, dynamic>> {
  const IdQueryParameterJsonConverter();
  static const _idKey = "id";
  static const _assignmentStatusKey = 'assignmentStatus';
  @override
  IdQueryParameter fromJson(Map<String, dynamic> json) {
    return IdQueryParameter(json[_assignmentStatusKey], json[_idKey]);
  }

  @override
  Map<String, dynamic> toJson(IdQueryParameter object) {
    return {
      _idKey: object.id,
      _assignmentStatusKey: object.assignmentStatus,
    };
  }
}
