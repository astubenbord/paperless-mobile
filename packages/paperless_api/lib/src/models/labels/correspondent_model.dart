import 'package:paperless_api/src/models/labels/label_model.dart';
import 'package:paperless_api/src/models/labels/matching_algorithm.dart';

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

  Correspondent.fromJson(Map<String, dynamic> json)
      : lastCorrespondence =
            DateTime.tryParse(json[lastCorrespondenceKey] ?? ''),
        super.fromJson(json);

  @override
  String toString() {
    return name;
  }

  @override
  void addSpecificFieldsToJson(Map<String, dynamic> json) {
    if (lastCorrespondence != null) {
      json.putIfAbsent(
          lastCorrespondenceKey, () => lastCorrespondence!.toIso8601String());
    }
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
