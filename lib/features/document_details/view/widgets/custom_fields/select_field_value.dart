import 'package:flutter/material.dart';

class SelectFieldValue extends StatelessWidget {
  final Object? id;
  final Object? extraData;
  final TextStyle? style;
  final Widget placeholder;

  const SelectFieldValue({
    super.key,
    required this.id,
    this.extraData,
    this.style,
    required this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    if (id == null) return placeholder;

    // extraData contains select options; try to resolve the label.
    final label = _resolveSelectLabel(id, extraData);
    return Text(label ?? '$id', style: style);
  }

  String? _resolveSelectLabel(Object? id, Object? extraData) {
    if (extraData is Map) {
      final options = extraData['select_options'];
      if (options is List) {
        for (final option in options) {
          if (option is Map && option['id'] == id) {
            return option['label']?.toString();
          }
        }
      }
    }
    // Fallback: return the raw value.
    return id?.toString();
  }
}
