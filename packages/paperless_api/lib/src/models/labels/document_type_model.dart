import 'package:paperless_api/src/models/labels/label_model.dart';
import 'package:paperless_api/src/models/labels/matching_algorithm.dart';

class DocumentType extends Label {
  DocumentType({
    required super.id,
    required super.name,
    super.slug,
    super.match,
    super.matchingAlgorithm,
    super.isInsensitive,
    super.documentCount,
  });

  DocumentType.fromJson(Map<String, dynamic> json) : super.fromJson(json);

  @override
  void addSpecificFieldsToJson(Map<String, dynamic> json) {}

  @override
  String get queryEndpoint => 'document_types';

  @override
  DocumentType copyWith({
    int? id,
    String? name,
    String? match,
    MatchingAlgorithm? matchingAlgorithm,
    bool? isInsensitive,
    int? documentCount,
    String? slug,
  }) {
    return DocumentType(
      id: id ?? this.id,
      name: name ?? this.name,
      match: match ?? this.match,
      matchingAlgorithm: matchingAlgorithm ?? this.matchingAlgorithm,
      isInsensitive: isInsensitive ?? this.isInsensitive,
      documentCount: documentCount ?? this.documentCount,
      slug: slug ?? this.slug,
    );
  }
}
