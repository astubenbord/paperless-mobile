import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:paperless_api/src/models/labels/matching_algorithm.dart';

abstract class Label extends Equatable implements Comparable {
  static const idKey = "id";
  static const nameKey = "name";
  static const slugKey = "slug";
  static const matchKey = "match";
  static const matchingAlgorithmKey = "matching_algorithm";
  static const isInsensitiveKey = "is_insensitive";
  static const documentCountKey = "document_count";

  String get queryEndpoint;
  @JsonKey()
  final int? id;
  @JsonKey()
  final String name;
  @JsonKey()
  final String? slug;
  @JsonKey()
  final String? match;
  @JsonKey()
  final MatchingAlgorithm? matchingAlgorithm;
  @JsonKey()
  final bool? isInsensitive;
  @JsonKey()
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

  Map<String, dynamic> toJson();
}
