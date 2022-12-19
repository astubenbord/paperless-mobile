import 'package:flutter/material.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/generated/l10n.dart';

class RelativeDateRangePickerHelper extends StatefulWidget {
  final FormFieldState<DateRangeQuery> field;
  final void Function(DateRangeQuery value)? onChanged;

  const RelativeDateRangePickerHelper({
    super.key,
    required this.field,
    this.onChanged,
  });

  @override
  State<RelativeDateRangePickerHelper> createState() =>
      _RelativeDateRangePickerHelperState();
}

class _RelativeDateRangePickerHelperState
    extends State<RelativeDateRangePickerHelper> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        itemCount: _options.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8.0),
        itemBuilder: (context, index) {
          final option = _options[index];
          return FilterChip(
            label: Text(option.title),
            onSelected: (isSelected) {
              final value =
                  isSelected ? option.value : const RelativeDateRangeQuery();
              widget.field.didChange(value);
              widget.onChanged?.call(value);
            },
            selected: widget.field.value == option.value,
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
}

class _ExtendedDateRangeQueryOption {
  final String title;
  final RelativeDateRangeQuery value;

  _ExtendedDateRangeQueryOption(this.title, this.value);
}
