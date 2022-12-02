import 'package:paperless_api/src/models/labels/label_model.dart';
import 'package:paperless_api/src/models/labels/matching_algorithm.dart';

class StoragePath extends Label {
  static const pathKey = 'path';

  late String? path;

  StoragePath({
    required super.id,
    required super.name,
    super.slug,
    super.match,
    super.matchingAlgorithm,
    super.isInsensitive,
    super.documentCount,
    required this.path,
  });

  StoragePath.fromJson(Map<String, dynamic> json)
      : path = json[pathKey],
        super.fromJson(json);

  @override
  String toString() {
    return name;
  }

  @override
  void addSpecificFieldsToJson(Map<String, dynamic> json) {
    json.putIfAbsent(
      pathKey,
      () => path,
    );
  }

  @override
  StoragePath copyWith({
    int? id,
    String? name,
    String? slug,
    String? match,
    MatchingAlgorithm? matchingAlgorithm,
    bool? isInsensitive,
    int? documentCount,
    String? path,
  }) {
    return StoragePath(
      id: id ?? this.id,
      name: name ?? this.name,
      documentCount: documentCount ?? documentCount,
      isInsensitive: isInsensitive ?? isInsensitive,
      path: path ?? this.path,
      match: match ?? this.match,
      matchingAlgorithm: matchingAlgorithm ?? this.matchingAlgorithm,
      slug: slug ?? this.slug,
    );
  }

  @override
  String get queryEndpoint => 'storage_paths';
}
