import 'package:json_annotation/json_annotation.dart';
import 'package:paperless_api/src/models/labels/label_model.dart';
import 'package:paperless_api/src/models/labels/matching_algorithm.dart';
part 'document_type_model.g.dart';

@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class DocumentType extends Label {
  const DocumentType({
    required super.id,
    required super.name,
    super.slug,
    super.match,
    super.matchingAlgorithm,
    super.isInsensitive,
    super.documentCount,
  });

  factory DocumentType.fromJson(Map<String, dynamic> json) =>
      _$DocumentTypeFromJson(json);

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

  @override
  Map<String, dynamic> toJson() => _$DocumentTypeToJson(this);

  @override
  List<Object?> get props => [
        id,
        name,
        slug,
        isInsensitive,
        documentCount,
        matchingAlgorithm,
        match,
      ];
}
