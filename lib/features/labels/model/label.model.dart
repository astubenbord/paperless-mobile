import 'package:equatable/equatable.dart';
import 'package:paperless_mobile/core/type/types.dart';
import 'package:paperless_mobile/extensions/dart_extensions.dart';
import 'package:paperless_mobile/features/labels/document_type/model/matching_algorithm.dart';

abstract class Label with EquatableMixin implements Comparable {
  static const idKey = "id";
  static const nameKey = "name";
  static const slugKey = "slug";
  static const matchKey = "match";
  static const matchingAlgorithmKey = "matching_algorithm";
  static const isInsensitiveKey = "is_insensitive";
  static const documentCountKey = "document_count";

  String get queryEndpoint;

  final int? id;
  final String name;
  final String? slug;
  final String? match;
  final MatchingAlgorithm? matchingAlgorithm;
  final bool? isInsensitive;
  final int? documentCount;

  const Label({
    required this.id,
    required this.name,
    this.match,
    this.matchingAlgorithm,
    this.isInsensitive,
    this.documentCount,
    this.slug,
  });

  Label.fromJson(JSON json)
      : id = json[idKey],
        name = json[nameKey],
        slug = json[slugKey],
        match = json[matchKey],
        matchingAlgorithm =
            MatchingAlgorithm.fromInt(json[matchingAlgorithmKey]),
        isInsensitive = json[isInsensitiveKey],
        documentCount = json[documentCountKey];

  JSON toJson() {
    JSON json = {};
    json.tryPutIfAbsent(idKey, () => id);
    json.tryPutIfAbsent(nameKey, () => name);
    json.tryPutIfAbsent(slugKey, () => slug);
    json.tryPutIfAbsent(matchKey, () => match);
    json.tryPutIfAbsent(matchingAlgorithmKey, () => matchingAlgorithm?.value);
    json.tryPutIfAbsent(isInsensitiveKey, () => isInsensitive);
    json.tryPutIfAbsent(documentCountKey, () => documentCount);
    addSpecificFieldsToJson(json);
    return json;
  }

  void addSpecificFieldsToJson(JSON json);

  Label copyWith({
    int? id,
    String? name,
    String? match,
    MatchingAlgorithm? matchingAlgorithm,
    bool? isInsensitive,
    int? documentCount,
    String? slug,
  });

  @override
  String toString() {
    return name;
  }

  @override
  int compareTo(dynamic other) {
    return toString().toLowerCase().compareTo(other.toString().toLowerCase());
  }

  @override
  List<Object?> get props => [id];
}
