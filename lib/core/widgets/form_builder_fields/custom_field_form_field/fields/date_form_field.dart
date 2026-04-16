import 'package:flutter/material.dart';
import 'package:paperless_mobile/api/constants/api_date_format.dart';
import 'package:paperless_mobile/core/extensions/context_extensions.dart';

/// A form field for editing a date custom field value.
///
/// The value is stored as an ISO 8601 date string (yyyy-MM-dd).
class DateFormField extends StatelessWidget {
  final Object? value;
  final bool enabled;
  final ValueChanged<Object?> onChanged;
  final String? errorText;
  final String labelText;

  const DateFormField({
    super.key,
    required this.value,
    required this.enabled,
    required this.onChanged,
    this.errorText,
    required this.labelText,
  });

  DateTime? _parseDate() {
    if (value == null) return null;
    return DateTime.tryParse('$value');
  }

  @override
  Widget build(BuildContext context) {
    final date = _parseDate();
    final displayText = date != null
        ? context.displayDateFormat.format(date)
        : '';

    return InkWell(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      onTap: enabled
          ? () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date ?? DateTime.now(),
                firstDate: DateTime(1000, 1, 1),
                lastDate: DateTime(9999, 12, 31),
              );
              if (picked != null) {
                // Store as ISO 8601 date string (yyyy-MM-dd).
                onChanged(apiDateFormat.format(picked));
              }
            }
          : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: labelText,
          errorText: errorText,
          isDense: true,
          prefixIcon: const Icon(Icons.calendar_today),
          suffixIcon: date != null && enabled
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => onChanged(null),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              : null,
        ),
        child: Text(displayText, style: Theme.of(context).textTheme.bodyLarge),
      ),
    );
  }
}
