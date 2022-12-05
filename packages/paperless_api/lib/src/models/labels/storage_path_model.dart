import 'package:json_annotation/json_annotation.dart';
import 'package:paperless_api/src/models/labels/label_model.dart';
import 'package:paperless_api/src/models/labels/matching_algorithm.dart';
part 'storage_path_model.g.dart';

@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
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

  factory StoragePath.fromJson(Map<String, dynamic> json) =>
      _$StoragePathFromJson(json);

  @override
  String toString() {
    return name;
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

  @override
  List<Object?> get props => [
        id,
        name,
        slug,
        isInsensitive,
        documentCount,
        path,
        matchingAlgorithm,
        match,
      ];

  @override
  Map<String, dynamic> toJson() => _$StoragePathToJson(this);
}
