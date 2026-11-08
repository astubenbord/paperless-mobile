import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:paperless_mobile/api/converters/hex_color_json_converter.dart';
import 'package:paperless_mobile/api/converters/local_date_time_json_converter.dart';
import 'package:paperless_mobile/api/models/labels/matching_algorithm.dart';

part 'label.g.dart';

@JsonEnum()
enum LabelType { correspondent, documentType, tag, storagePath }

sealed class Label extends Equatable implements Comparable {
  static const idKey = "id";
  static const nameKey = "name";
  static const slugKey = "slug";
  static const matchKey = "match";
  static const matchingAlgorithmKey = "matching_algorithm";
  static const isInsensitiveKey = "is_insensitive";
  static const documentCountKey = "document_count";

  final int id;
  final String name;
  final String? slug;
  final String match;
  final MatchingAlgorithm matchingAlgorithm;
  final bool? isInsensitive;
  final int? documentCount;
  final int? owner;
  final bool? userCanChange;

  const Label({
    required this.id,
    required this.name,
    this.matchingAlgorithm = MatchingAlgorithm.defaultValue,
    this.match = "",
    this.isInsensitive = true,
    this.documentCount,
    this.slug,
    this.owner,
    this.userCanChange,
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
    return name.toLowerCase().compareTo(other.name.toLowerCase());
  }

  Map<String, dynamic> toJson();
}

@LocalDateTimeJsonConverter()
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class Correspondent extends Label {
  final DateTime? lastCorrespondence;

  const Correspondent({
    this.lastCorrespondence,
    required super.name,
    required super.id,
    super.slug,
    super.match,
    super.matchingAlgorithm,
    super.isInsensitive,
    super.documentCount,
    super.owner,
    super.userCanChange,
  });

  factory Correspondent.fromJson(Map<String, dynamic> json) =>
      _$CorrespondentFromJson(json);

  @override
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
    super.owner,
    super.userCanChange,
  });

  factory DocumentType.fromJson(Map<String, dynamic> json) =>
      _$DocumentTypeFromJson(json);

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

@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class StoragePath extends Label {
  static const pathKey = 'path';
  final String path;

  const StoragePath({
    required super.id,
    required super.name,
    this.path = '',
    super.slug,
    super.match,
    super.matchingAlgorithm,
    super.isInsensitive,
    super.documentCount,
    super.owner,
    super.userCanChange,
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

@HexColorJsonConverter()
@JsonSerializable(fieldRename: FieldRename.snake)
class Tag extends Label {
  static const colorKey = 'color';
  static const isInboxTagKey = 'is_inbox_tag';
  static const textColorKey = 'text_color';
  static const legacyColourKey = 'colour';
  final Color? textColor;
  final Color? color;

  final bool isInboxTag;
  final int? parent;
  final List<Tag>? children;

  const Tag({
    required super.id,
    required super.name,
    super.documentCount,
    super.isInsensitive,
    super.match,
    super.matchingAlgorithm = MatchingAlgorithm.defaultValue,
    super.slug,
    this.color,
    this.textColor,
    this.isInboxTag = false,
    this.parent,
    this.children,
    super.owner,
    super.userCanChange,
  });

  @override
  String toString() => name;

  @override
  Tag copyWith({
    int? id,
    String? name,
    String? match,
    MatchingAlgorithm? matchingAlgorithm,
    bool? isInsensitive,
    int? documentCount,
    String? slug,
    Color? color,
    Color? textColor,
    bool? isInboxTag,
    int? parent,
    List<Tag>? children,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      match: match ?? this.match,
      matchingAlgorithm: matchingAlgorithm ?? this.matchingAlgorithm,
      isInsensitive: isInsensitive ?? this.isInsensitive,
      documentCount: documentCount ?? this.documentCount,
      slug: slug ?? this.slug,
      color: color ?? this.color,
      textColor: textColor ?? this.textColor,
      isInboxTag: isInboxTag ?? this.isInboxTag,
      parent: parent ?? this.parent,
      children: children ?? this.children,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    slug,
    isInsensitive,
    documentCount,
    matchingAlgorithm,
    color,
    textColor,
    isInboxTag,
    parent,
    children,
    match,
  ];

  factory Tag.fromJson(Map<String, dynamic> json) => _$TagFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$TagToJson(this);
}
