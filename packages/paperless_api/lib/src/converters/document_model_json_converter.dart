import 'package:json_annotation/json_annotation.dart';
import 'package:paperless_api/src/models/document_model.dart';

class DocumentModelJsonConverter
    extends JsonConverter<DocumentModel, Map<String, dynamic>> {
  @override
  DocumentModel fromJson(Map<String, dynamic> json) {
    return DocumentModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(DocumentModel object) {
    return object.toJson();
  }
}
