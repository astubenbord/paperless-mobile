import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/widgets/form_builder_fields/extended_date_range_form_field/extended_date_range_dialog.dart';
import 'package:paperless_mobile/core/widgets/form_builder_fields/extended_date_range_form_field/relative_date_range_picker_helper.dart';
import 'package:paperless_mobile/generated/l10n.dart';

class FormBuilderExtendedDateRangePicker extends StatefulWidget {
  final String name;
  final String labelText;
  final DateRangeQuery initialValue;
  final void Function(DateRangeQuery? query)? onChanged;
  const FormBuilderExtendedDateRangePicker({
    super.key,
    required this.name,
    required this.labelText,
    required this.initialValue,
    this.onChanged,
  });

  @override
  State<FormBuilderExtendedDateRangePicker> createState() =>
      _FormBuilderExtendedDateRangePickerState();
}

class _FormBuilderExtendedDateRangePickerState
    extends State<FormBuilderExtendedDateRangePicker> {
  final TextEditingController _textEditingController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This has to be initialized here and not in initState because it has to be waited until dependencies for localization have been loaded.
    _textEditingController.text = _dateRangeQueryToString(widget.initialValue);
  }

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<DateRangeQuery>(
      name: widget.name,
      initialValue: widget.initialValue,
      onChanged: (query) {
        _textEditingController.text =
            _dateRangeQueryToString(query ?? const UnsetDateRangeQuery());
        widget.onChanged?.call(query);
      },
      builder: (field) {
        return Column(
          children: [
            TextFormField(
              controller: _textEditingController,
              readOnly: true,
              onTap: () => _showExtendedDateRangePicker(field),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.date_range),
                labelText: widget.labelText,
                suffixIcon: _textEditingController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          field.didChange(const UnsetDateRangeQuery());
                        },
                      )
                    : null,
              ),
            ),
            RelativeDateRangePickerHelper(field: field),
          ],
        );
      },
    );
  }

  String _dateRangeQueryToString(DateRangeQuery query) {
    final df = DateFormat.yMd();
    if (query is UnsetDateRangeQuery) {
      return '';
    } else if (query is AbsoluteDateRangeQuery) {
      if (query.before != null && query.after != null) {
        if (query.before!.isAtSameMomentAs(query.after!)) {
          return df.format(query.before!);
        }
        return '${df.format(query.after!)} – ${df.format(query.before!)}';
      }
      if (query.before != null) {
        return '${S.of(context).extendedDateRangePickerBeforeLabel} ${df.format(query.before!)}';
      }
      if (query.after != null) {
        return '${S.of(context).extendedDateRangePickerAfterLabel} ${df.format(query.after!)}';
      }
    } else if (query is RelativeDateRangeQuery) {
      switch (query.unit) {
        case DateRangeUnit.day:
          return S
              .of(context)
              .extendedDateRangePickerLastDaysLabel(query.offset);
        case DateRangeUnit.week:
          return S
              .of(context)
              .extendedDateRangePickerLastWeeksLabel(query.offset);
        case DateRangeUnit.month:
          return S
              .of(context)
              .extendedDateRangePickerLastMonthsLabel(query.offset);
        case DateRangeUnit.year:
          return S
              .of(context)
              .extendedDateRangePickerLastYearsLabel(query.offset);
        default:
      }
    }
    return '';
  }

  void _showExtendedDateRangePicker(
    FormFieldState<DateRangeQuery> field,
  ) async {
    final query = await showDialog<DateRangeQuery>(
      context: context,
      builder: (context) => ExtendedDateRangeDialog(initialValue: field.value!),
    );
    if (query != null) {
      field.didChange(query);
    }
  }
}
