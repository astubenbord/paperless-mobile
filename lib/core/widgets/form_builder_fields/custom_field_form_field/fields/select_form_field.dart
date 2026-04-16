import 'package:flutter/material.dart';

/// A form field for editing a select custom field value.
///
/// Options are extracted from `extraData`, which has the structure:
/// ```json
/// {
///   "select_options": [
///     { "value": <dynamic>, "label": "<string>" }
///   ]
/// }
/// ```
class SelectFormField extends StatelessWidget {
  final String labelText;
  final Object? value;
  final Object? extraData;
  final bool enabled;
  final ValueChanged<Object?> onChanged;
  final String? errorText;

  const SelectFormField({
    super.key,
    required this.labelText,
    required this.value,
    required this.extraData,
    required this.enabled,
    required this.onChanged,
    this.errorText,
  });

  List<Map<String, dynamic>> _parseOptions() {
    if (extraData is Map) {
      final options = (extraData as Map)['select_options'];
      if (options is List) {
        return options.whereType<Map<String, dynamic>>().toList();
      }
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final options = _parseOptions();

    return DropdownButtonFormField<Object?>(
      initialValue: _findMatchingValue(options),
      onChanged: enabled ? onChanged : null,
      decoration: InputDecoration(
        labelText: labelText,
        errorText: errorText,
        isDense: true,
      ),
      items: [
        // Allow clearing the selection.
        const DropdownMenuItem<Object?>(value: null, child: Text('-')),
        ...options.map(
          (option) => DropdownMenuItem<Object?>(
            value: option['id'],
            child: Text('${option['label']}'),
          ),
        ),
      ],
    );
  }

  /// Finds the matching option value, accounting for type differences
  /// (e.g. the value may be stored as an int or string).
  Object? _findMatchingValue(List<dynamic> options) {
    if (value == null) return null;
    for (final option in options) {
      if (option == value || '$option' == '$value') {
        return option;
      }
    }
    return null;
  }
}
