import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/generated/l10n.dart';

class FormBuilderRelativeDateRangePicker extends StatefulWidget {
  final String name;
  final RelativeDateRangeQuery initialValue;
  const FormBuilderRelativeDateRangePicker({
    super.key,
    required this.name,
    required this.initialValue,
  });

  @override
  State<FormBuilderRelativeDateRangePicker> createState() =>
      _FormBuilderRelativeDateRangePickerState();
}

class _FormBuilderRelativeDateRangePickerState
    extends State<FormBuilderRelativeDateRangePicker> {
  late int _offset;
  @override
  void initState() {
    super.initState();
    _offset = widget.initialValue.offset;
  }

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<RelativeDateRangeQuery>(
      name: widget.name,
      initialValue: widget.initialValue,
      builder: (field) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Last"),
          SizedBox(
            width: 70,
            child: TextFormField(
              decoration: InputDecoration(
                labelText: "Offset",
              ),
              initialValue: widget.initialValue.offset.toString(),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r"[1-9][0-9]*"))
              ],
              validator: FormBuilderValidators.numeric(),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final parsed = int.parse(value);
                setState(() {
                  _offset = parsed;
                });
                field.didChange(field.value!.copyWith(offset: parsed));
              },
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
          )
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
