import 'package:paperless_mobile/core/type/json.dart';
import 'package:paperless_mobile/features/labels/document_type/model/matching_algorithm.dart';
import 'package:paperless_mobile/features/labels/model/label.model.dart';

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

  DocumentType.fromJson(JSON json) : super.fromJson(json);

  @override
  void addSpecificFieldsToJson(JSON json) {}

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
