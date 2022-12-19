import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/widgets/form_builder_fields/extended_date_range_dialog.dart';
import 'package:paperless_mobile/generated/l10n.dart';

class FormBuilderExtendedDateRangePicker extends StatefulWidget {
  final String name;
  final String labelText;
  final DateRangeQuery initialValue;

  const FormBuilderExtendedDateRangePicker({
    super.key,
    required this.name,
    required this.labelText,
    required this.initialValue,
  });

  @override
  State<FormBuilderExtendedDateRangePicker> createState() =>
      _FormBuilderExtendedDateRangePickerState();
}

class _FormBuilderExtendedDateRangePickerState
    extends State<FormBuilderExtendedDateRangePicker> {
  late final TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController(
        text: _dateRangeQueryToString(widget.initialValue));
  }

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<DateRangeQuery>(
      name: widget.name,
      initialValue: widget.initialValue,
      onChanged: (query) {
        _textEditingController.text =
            _dateRangeQueryToString(query ?? const UnsetDateRangeQuery());
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
              ),
            ),
            _buildExtendedQueryOptions(field),
          ],
        );
      },
    );
  }

  Widget _buildExtendedQueryOptions(FormFieldState<DateRangeQuery> field) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        itemCount: _options.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8.0),
        itemBuilder: (context, index) {
          final option = _options[index];
          return FilterChip(
            label: Text(option.title),
            onSelected: (isSelected) => isSelected
                ? field.didChange(option.value)
                : field.didChange(const UnsetDateRangeQuery()),
            selected: field.value == option.value,
          );
        },
        scrollDirection: Axis.horizontal,
      ),
    );
  }

  List<_ExtendedDateRangeQueryOption> get _options => [
        _ExtendedDateRangeQueryOption(
          S.of(context).extendedDateRangePickerLastWeeksLabel(1),
          const RelativeDateRangeQuery(1, DateRangeUnit.week),
        ),
        _ExtendedDateRangeQueryOption(
          S.of(context).extendedDateRangePickerLastMonthsLabel(1),
          const RelativeDateRangeQuery(1, DateRangeUnit.month),
        ),
        _ExtendedDateRangeQueryOption(
          S.of(context).extendedDateRangePickerLastMonthsLabel(3),
          const RelativeDateRangeQuery(3, DateRangeUnit.month),
        ),
        _ExtendedDateRangeQueryOption(
          S.of(context).extendedDateRangePickerLastYearsLabel(1),
          const RelativeDateRangeQuery(1, DateRangeUnit.year),
        ),
      ];

  String _dateRangeQueryToString(DateRangeQuery query) {
    if (query is UnsetDateRangeQuery) {
      return '';
    } else if (query is AbsoluteDateRangeQuery) {
      if (query.before != null && query.after != null) {
        return '${DateFormat.yMd(query.after)} – ${DateFormat.yMd(query.before)}';
      }
      if (query.before != null) {
        return '${S.of(context).extendedDateRangePickerBeforeLabel} ${DateFormat.yMd(query.before)}';
      }
      if (query.after != null) {
        return '${S.of(context).extendedDateRangePickerAfterLabel} ${DateFormat.yMd(query.after)}';
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
      builder: (context) => ExtendedDateRangeDialog(
        initialValue: field.value!,
        stringTransformer: _dateRangeQueryToString,
      ),
    );
    if (query != null) {
      field.didChange(query);
    }
  }
}

class _ExtendedDateRangeQueryOption {
  final String title;
  final RelativeDateRangeQuery value;

  _ExtendedDateRangeQueryOption(this.title, this.value);
}
