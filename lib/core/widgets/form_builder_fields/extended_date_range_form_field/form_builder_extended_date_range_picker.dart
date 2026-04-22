import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:paperless_mobile/api/paperless_api.dart';
import 'package:paperless_mobile/core/extensions/context_extensions.dart';
import 'package:paperless_mobile/core/widgets/form_builder_fields/extended_date_range_form_field/extended_date_range_dialog.dart';
import 'package:paperless_mobile/core/widgets/form_builder_fields/extended_date_range_form_field/relative_date_range_picker_helper.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class FormBuilderExtendedDateRangePicker extends StatefulWidget {
  final String name;
  final String labelText;
  final DateRangeQuery initialValue;
  final void Function(DateRangeQuery? query)? onChanged;
  final EdgeInsets padding;

  const FormBuilderExtendedDateRangePicker({
    super.key,
    required this.name,
    required this.labelText,
    required this.initialValue,
    this.onChanged,
    required this.padding,
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
        _textEditingController.text = _dateRangeQueryToString(
          query ?? const UnsetDateRangeQuery(),
        );
        widget.onChanged?.call(query);
      },
      builder: (field) {
        return Column(
          children: [
            Padding(
              padding: widget.padding.copyWith(bottom: 0),
              child: TextFormField(
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
            ),
            RelativeDateRangePickerHelper(
              field: field,
              padding: widget.padding,
            ),
            // MediaQuery.removePadding(
            //context: context,
            //removeLeft: true,
            //removeRight: true,
            //child: ,
            //),
          ],
        );
      },
    );
  }

  String _dateRangeQueryToString(DateRangeQuery query) {
    final df = context.displayDateFormat;
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
        return '${S.of(context)!.before} ${df.format(query.before!)}';
      }
      if (query.after != null) {
        return '${S.of(context)!.after} ${df.format(query.after!)}';
      }
    } else if (query is ExactDateQuery) {
      return df.format(query.date);
    } else if (query is RelativeDateRangeQuery) {
      switch (query.unit) {
        case DateRangeUnit.day:
          return S.of(context)!.lastNDays(query.offset);
        case DateRangeUnit.week:
          return S.of(context)!.lastNWeeks(query.offset);
        case DateRangeUnit.month:
          return S.of(context)!.lastNMonths(query.offset);
        case DateRangeUnit.year:
          return S.of(context)!.lastNYears(query.offset);
      }
    }
    return '';
  }

  void _showExtendedDateRangePicker(
    FormFieldState<DateRangeQuery> field,
  ) async {
    final query = await showDialog<DateRangeQuery>(
      useRootNavigator: false,
      context: context,
      builder: (context) => ExtendedDateRangeDialog(initialValue: field.value!),
    );
    if (query != null) {
      field.didChange(query);
    }
  }
}
