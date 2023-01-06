import 'package:json_annotation/json_annotation.dart';
import 'package:paperless_api/paperless_api.dart';

class SimilarDocumentModelJsonConverter
    extends JsonConverter<SimilarDocumentModel, Map<String, dynamic>> {
  @override
  SimilarDocumentModel fromJson(Map<String, dynamic> json) {
    return SimilarDocumentModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(SimilarDocumentModel object) {
    return object.toJson();
  }
}
