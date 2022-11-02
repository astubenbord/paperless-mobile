import 'dart:developer';
import 'dart:ui';

import 'package:paperless_mobile/core/type/json.dart';
import 'package:paperless_mobile/extensions/dart_extensions.dart';
import 'package:paperless_mobile/features/labels/document_type/model/matching_algorithm.dart';
import 'package:paperless_mobile/features/labels/model/label.model.dart';

class Tag extends Label {
  static const colorKey = 'color';
  static const isInboxTagKey = 'is_inbox_tag';
  static const textColorKey = 'text_color';

  final Color? color;
  final Color? textColor;
  final bool? isInboxTag;

  Tag({
    required super.id,
    required super.name,
    super.documentCount,
    super.isInsensitive,
    super.match,
    super.matchingAlgorithm,
    super.slug,
    this.color,
    this.textColor,
    this.isInboxTag,
  });

  Tag.fromJson(JSON json)
      : isInboxTag = json[isInboxTagKey],
        textColor = Color(_colorStringToInt(json[textColorKey]) ?? 0),
        color = (json[colorKey] is Color)
            ? json[colorKey]
            : Color(_colorStringToInt(json[colorKey]) ?? 0),
        super.fromJson(json);

  @override
  String toString() {
    return name;
  }

  @override
  void addSpecificFieldsToJson(JSON json) {
    json.tryPutIfAbsent(colorKey, () => _toHex(color));
    json.tryPutIfAbsent(isInboxTagKey, () => isInboxTag);
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
}

///
/// Taken from [FormBuilderColorPicker].
///
String? _toHex(Color? color) {
  if (color == null) {
    return null;
  }
  String val = '#${(color.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toLowerCase()}';
  log("Color in Tag#_toHex is $val");
  return val;
}

int? _colorStringToInt(String? color) {
  if (color == null) return null;
  return int.tryParse(color.replaceAll("#", "ff"), radix: 16);
}
