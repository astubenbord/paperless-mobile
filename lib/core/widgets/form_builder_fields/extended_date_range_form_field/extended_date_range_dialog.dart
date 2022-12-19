import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/widgets/form_builder_fields/extended_date_range_form_field/form_builder_relative_date_range_field.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/generated/l10n.dart';

class ExtendedDateRangeDialog extends StatefulWidget {
  final DateRangeQuery initialValue;

  const ExtendedDateRangeDialog({
    super.key,
    required this.initialValue,
  });

  @override
  State<ExtendedDateRangeDialog> createState() =>
      _ExtendedDateRangeDialogState();
}

class _ExtendedDateRangeDialogState extends State<ExtendedDateRangeDialog> {
  static const String _fkAbsoluteBefore = 'absoluteBefore';
  static const String _fkAbsoluteAfter = 'absoluteAfter';
  static const String _fkRelative = 'relative';

  DateTime? _before;
  DateTime? _after;

  final _formKey = GlobalKey<FormBuilderState>();
  late DateRangeType _selectedDateRangeType;

  @override
  void initState() {
    super.initState();
    final initialQuery = widget.initialValue;
    if (initialQuery is AbsoluteDateRangeQuery) {
      _before = initialQuery.before;
      _after = initialQuery.after;
    }
    _selectedDateRangeType = (initialQuery is RelativeDateRangeQuery)
        ? DateRangeType.relative
        : DateRangeType.absolute;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Select date range"),
      content: FormBuilder(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateRangeQueryTypeSelection(),
            Text(
              "Hint: You can either specify absolute values by selecting concrete dates, or you can specify a time range relative to the current date.",
              style: Theme.of(context).textTheme.bodySmall,
            ).paddedOnly(top: 8, bottom: 16),
            Builder(
              builder: (context) {
                switch (_selectedDateRangeType) {
                  case DateRangeType.absolute:
                    return _buildAbsoluteDateRangeForm();
                  case DateRangeType.relative:
                    return FormBuilderRelativeDateRangePicker(
                      name: _fkRelative,
                      initialValue:
                          widget.initialValue is RelativeDateRangeQuery
                              ? widget.initialValue as RelativeDateRangeQuery
                              : const RelativeDateRangeQuery(
                                  1,
                                  DateRangeUnit.month,
                                ),
                    );
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text(S.of(context).genericActionCancelLabel),
          onPressed: () => Navigator.pop(context),
        ),
        TextButton(
          child: Text(S.of(context).genericActionSaveLabel),
          onPressed: () {
            _formKey.currentState?.save();
            if (_formKey.currentState?.validate() ?? false) {
              final values = _formKey.currentState!.value;
              final query = _buildQuery(values);
              Navigator.pop(context, query);
            }
          },
        ),
      ],
    );
  }

  Widget _buildDateRangeQueryTypeSelection() {
    return SegmentedButton<DateRangeType>(
      multiSelectionEnabled: false,
      onSelectionChanged: (selection) =>
          setState(() => _selectedDateRangeType = selection.first),
      segments: [
        ButtonSegment(
          value: DateRangeType.absolute,
          enabled: true,
          label: Text("Absolute"),
        ),
        ButtonSegment(
          value: DateRangeType.relative,
          enabled: true,
          label: Text("Relative"),
        ),
      ],
      selected: {_selectedDateRangeType},
    );
  }

  Widget _buildAbsoluteDateRangeForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        FormBuilderDateTimePicker(
          name: _fkAbsoluteAfter,
          initialValue: widget.initialValue is AbsoluteDateRangeQuery
              ? (widget.initialValue as AbsoluteDateRangeQuery).after
              : null,
          initialDate: _before?.subtract(const Duration(days: 1)),
          decoration: InputDecoration(
            labelText: S.of(context).extendedDateRangePickerAfterLabel,
            prefixIcon: const Icon(Icons.date_range),
            suffixIcon: _after != null
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _formKey.currentState?.fields[_fkAbsoluteAfter]
                          ?.didChange(null);
                      setState(() => _after = null);
                    },
                  )
                : null,
          ),
          format: DateFormat.yMd(),
          lastDate: _dateTimeMax(_before, DateTime.now()),
          inputType: InputType.date,
          onChanged: (after) {
            setState(() => _after = after);
          },
        ),
        const SizedBox(height: 16),
        FormBuilderDateTimePicker(
          name: _fkAbsoluteBefore,
          initialValue: widget.initialValue is AbsoluteDateRangeQuery
              ? (widget.initialValue as AbsoluteDateRangeQuery).before
              : null,
          inputType: InputType.date,
          decoration: InputDecoration(
            labelText: S.of(context).extendedDateRangePickerBeforeLabel,
            prefixIcon: const Icon(Icons.date_range),
            suffixIcon: _before != null
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _formKey.currentState?.fields[_fkAbsoluteBefore]
                          ?.didChange(null);
                      setState(() => _before = null);
                    },
                  )
                : null,
          ),
          format: DateFormat.yMd(),
          firstDate: _after,
          lastDate: DateTime.now(),
          onChanged: (before) {
            setState(() => _before = before);
          },
        ),
      ],
    );
  }

  DateRangeQuery? _buildQuery(Map<String, dynamic> values) {
    if (_selectedDateRangeType == DateRangeType.absolute) {
      return AbsoluteDateRangeQuery(
        after: values[_fkAbsoluteAfter],
        before: values[_fkAbsoluteBefore],
      );
    } else {
      return values[_fkRelative] as RelativeDateRangeQuery;
    }
  }

  DateTime? _dateTimeMax(DateTime? dt1, DateTime? dt2) {
    if (dt1 == null) return dt2;
    if (dt2 == null) return dt1;
    return dt1.compareTo(dt2) >= 0 ? dt1 : dt2;
  }
}

enum DateRangeType {
  absolute,
  relative;
}
