import 'dart:developer';
import 'dart:ui';

import 'package:json_annotation/json_annotation.dart';
import 'package:paperless_api/src/models/labels/label_model.dart';
import 'package:paperless_api/src/models/labels/matching_algorithm.dart';

class Tag extends Label {
  static const colorKey = 'color';
  static const isInboxTagKey = 'is_inbox_tag';
  static const textColorKey = 'text_color';
  static const legacyColourKey = 'colour';

  final Color? _apiV2color;

  final Color? _apiV1color;

  final Color? textColor;

  final bool? isInboxTag;

  Color? get color => _apiV2color ?? _apiV1color;

  const Tag({
    required super.id,
    required super.name,
    super.documentCount,
    super.isInsensitive,
    super.match,
    super.matchingAlgorithm,
    super.slug,
    Color? color,
    this.textColor,
    this.isInboxTag,
  })  : _apiV1color = color,
        _apiV2color = color;

  @override
  String toString() {
    return name;
  }

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
    );
  }

  @override
  String get queryEndpoint => 'tags';

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
        match,
      ];

  factory Tag.fromJson(Map<String, dynamic> json) {
    const $MatchingAlgorithmEnumMap = {
      MatchingAlgorithm.anyWord: 1,
      MatchingAlgorithm.allWords: 2,
      MatchingAlgorithm.exactMatch: 3,
      MatchingAlgorithm.regex: 4,
      MatchingAlgorithm.similarWord: 5,
      MatchingAlgorithm.auto: 6,
    };

    return Tag(
      id: json['id'] as int?,
      name: json['name'] as String,
      documentCount: json['document_count'] as int?,
      isInsensitive: json['is_insensitive'] as bool?,
      match: json['match'] as String?,
      matchingAlgorithm: $enumDecodeNullable(
          $MatchingAlgorithmEnumMap, json['matching_algorithm']),
      slug: json['slug'] as String?,
      textColor: _colorFromJson(json['text_color']),
      isInboxTag: json['is_inbox_tag'] as bool?,
      color: _colorFromJson(json['color']) ?? _colorFromJson(json['colour']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final val = <String, dynamic>{};

    const $MatchingAlgorithmEnumMap = {
      MatchingAlgorithm.anyWord: 1,
      MatchingAlgorithm.allWords: 2,
      MatchingAlgorithm.exactMatch: 3,
      MatchingAlgorithm.regex: 4,
      MatchingAlgorithm.similarWord: 5,
      MatchingAlgorithm.auto: 6,
    };

    void writeNotNull(String key, dynamic value) {
      if (value != null) {
        val[key] = value;
      }
    }

    writeNotNull('id', id);
    val['name'] = name;
    writeNotNull('slug', slug);
    writeNotNull('match', match);
    writeNotNull(
        'matching_algorithm', $MatchingAlgorithmEnumMap[matchingAlgorithm]);
    writeNotNull('is_insensitive', isInsensitive);
    writeNotNull('document_count', documentCount);
    writeNotNull('color', _toHex(_apiV2color));
    writeNotNull('colour', _toHex(_apiV1color));
    writeNotNull('text_color', _toHex(textColor));
    writeNotNull('is_inbox_tag', isInboxTag);
    return val;
  }

  static Color? _colorFromJson(dynamic color) {
    if (color is Color) {
      return color;
    }
    if (color is String) {
      final decoded = int.tryParse(color.replaceAll("#", "ff"), radix: 16);
      if (decoded == null) {
        return null;
      }
      return Color(decoded);
    }
    return null;
  }

  ///
  /// Taken from [FormBuilderColorPicker].
  ///
  static String? _toHex(Color? color) {
    if (color == null) {
      return null;
    }
    String val =
        '#${(color.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toLowerCase()}';
    return val;
  }
}
