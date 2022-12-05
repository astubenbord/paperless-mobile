import 'package:json_annotation/json_annotation.dart';
import 'package:paperless_api/src/models/labels/label_model.dart';
import 'package:paperless_api/src/models/labels/matching_algorithm.dart';

part 'correspondent_model.g.dart';

@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class Correspondent extends Label {
  final DateTime? lastCorrespondence;

  const Correspondent({
    required super.id,
    required super.name,
    super.slug,
    super.match,
    super.matchingAlgorithm,
    super.isInsensitive,
    super.documentCount,
    this.lastCorrespondence,
  });

  factory Correspondent.fromJson(Map<String, dynamic> json) =>
      _$CorrespondentFromJson(json);

  Map<String, dynamic> toJson() => _$CorrespondentToJson(this);

  @override
  String toString() {
    return name;
  }

  @override
  Correspondent copyWith({
    int? id,
    String? name,
    String? slug,
    String? match,
    MatchingAlgorithm? matchingAlgorithm,
    bool? isInsensitive,
    int? documentCount,
    DateTime? lastCorrespondence,
  }) {
    return Correspondent(
      id: id ?? this.id,
      name: name ?? this.name,
      documentCount: documentCount ?? documentCount,
      isInsensitive: isInsensitive ?? isInsensitive,
      match: match ?? this.match,
      matchingAlgorithm: matchingAlgorithm ?? this.matchingAlgorithm,
      slug: slug ?? this.slug,
      lastCorrespondence: lastCorrespondence ?? this.lastCorrespondence,
    );
  }

  @override
  String get queryEndpoint => 'correspondents';

  @override
  List<Object?> get props => [
        id,
        name,
        slug,
        isInsensitive,
        documentCount,
        lastCorrespondence,
        matchingAlgorithm,
        match,
      ];
}
