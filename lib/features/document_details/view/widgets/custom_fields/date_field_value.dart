import 'package:flutter/material.dart';
import 'package:paperless_mobile/core/extensions/context_extensions.dart';

class DateFieldValue extends StatelessWidget {
  final Object? value;
  final TextStyle? style;
  final Widget placeholder;

  const DateFieldValue({
    super.key,
    required this.value,
    this.style,
    required this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    if (value == null) return placeholder;
    try {
      final date = DateTime.parse('$value');
      return Text(context.displayDateFormat.format(date), style: style);
    } catch (_) {
      return Text('$value', style: style);
    }
  }
}
