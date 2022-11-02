import 'package:paperless_mobile/core/type/json.dart';
import 'package:paperless_mobile/extensions/dart_extensions.dart';
import 'package:paperless_mobile/features/labels/document_type/model/matching_algorithm.dart';
import 'package:paperless_mobile/features/labels/model/label.model.dart';

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

  StoragePath.fromJson(JSON json)
      : path = json[pathKey],
        super.fromJson(json);

  @override
  String toString() {
    return name;
  }

  @override
  void addSpecificFieldsToJson(JSON json) {
    json.tryPutIfAbsent(
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
