import 'package:paperless_mobile/core/type/types.dart';
import 'package:paperless_mobile/extensions/dart_extensions.dart';
import 'package:paperless_mobile/features/labels/document_type/model/matching_algorithm.dart';
import 'package:paperless_mobile/features/labels/model/label.model.dart';

class Correspondent extends Label {
  static const lastCorrespondenceKey = 'last_correspondence';

  late DateTime? lastCorrespondence;

  Correspondent({
    required super.id,
    required super.name,
    super.slug,
    super.match,
    super.matchingAlgorithm,
    super.isInsensitive,
    super.documentCount,
    this.lastCorrespondence,
  });

  Correspondent.fromJson(JSON json)
      : lastCorrespondence =
            DateTime.tryParse(json[lastCorrespondenceKey] ?? ''),
        super.fromJson(json);

  @override
  String toString() {
    return name;
  }

  @override
  void addSpecificFieldsToJson(JSON json) {
    json.tryPutIfAbsent(
      lastCorrespondenceKey,
      () => lastCorrespondence?.toIso8601String(),
    );
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
      lastCorrespondence: lastCorrespondence ?? this.lastCorrespondence,
      match: match ?? this.match,
      matchingAlgorithm: matchingAlgorithm ?? this.matchingAlgorithm,
      slug: slug ?? this.slug,
    );
  }

  @override
  String get queryEndpoint => 'correspondents';
}
