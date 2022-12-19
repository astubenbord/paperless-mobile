import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/widgets/form_builder_fields/extended_date_range_form_field/relative_date_range_picker_helper.dart';
import 'package:paperless_mobile/generated/l10n.dart';

class FormBuilderRelativeDateRangePicker extends StatefulWidget {
  final String name;
  final RelativeDateRangeQuery initialValue;
  final void Function(RelativeDateRangeQuery? query)? onChanged;
  const FormBuilderRelativeDateRangePicker({
    super.key,
    required this.name,
    required this.initialValue,
    this.onChanged,
  });

  @override
  State<FormBuilderRelativeDateRangePicker> createState() =>
      _FormBuilderRelativeDateRangePickerState();
}

class _FormBuilderRelativeDateRangePickerState
    extends State<FormBuilderRelativeDateRangePicker> {
  late int _offset;
  late final TextEditingController _offsetTextEditingController;

  @override
  void initState() {
    super.initState();
    _offset = widget.initialValue.offset;
    _offsetTextEditingController = TextEditingController(
      text: widget.initialValue.offset.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<RelativeDateRangeQuery>(
      name: widget.name,
      initialValue: widget.initialValue,
      onChanged: widget.onChanged?.call,
      builder: (field) => Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Last"),
              SizedBox(
                width: 70,
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: "Offset",
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: FormBuilderValidators.numeric(),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final parsed = int.tryParse(value);
                    if (parsed != null) {
                      setState(() {
                        _offset = parsed;
                      });
                      field.didChange((field.value)?.copyWith(offset: parsed));
                    }
                  },
                  controller: _offsetTextEditingController,
                ),
              ),
              SizedBox(
                width: 120,
                child: DropdownButtonFormField<DateRangeUnit?>(
                  value: field.value?.unit,
                  items: DateRangeUnit.values
                      .map(
                        (unit) => DropdownMenuItem(
                          child: Text(
                            _dateRangeUnitToLocalizedString(
                              unit,
                              _offset,
                            ),
                          ),
                          value: unit,
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      field.didChange(field.value!.copyWith(unit: value)),
                  decoration: InputDecoration(
                    labelText: "Amount",
                  ),
                ),
              ),
            ],
          ),
          // RelativeDateRangePickerHelper(
          //   field: field,
          //   onChanged: (value) {
          //     if (value is RelativeDateRangeQuery) {
          //       setState(() => _offset = value.offset);
          //       _offsetTextEditingController.text = _offset.toString();
          //     }
          //   },
          // ),
        ],
      ),
    );
  }

  String _dateRangeUnitToLocalizedString(DateRangeUnit unit, int? count) {
    switch (unit) {
      case DateRangeUnit.day:
        return S.of(context).extendedDateRangePickerDayText(count ?? 1);
      case DateRangeUnit.week:
        return S.of(context).extendedDateRangePickerWeekText(count ?? 1);
      case DateRangeUnit.month:
        return S.of(context).extendedDateRangePickerMonthText(count ?? 1);
      case DateRangeUnit.year:
        return S.of(context).extendedDateRangePickerYearText(count ?? 1);
    }
  }
}
