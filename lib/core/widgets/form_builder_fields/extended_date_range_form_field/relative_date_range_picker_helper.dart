import 'package:flutter/material.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/widgets/colored_chip.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class RelativeDateRangePickerHelper extends StatefulWidget {
  final FormFieldState<DateRangeQuery> field;
  final void Function(DateRangeQuery value)? onChanged;
  final EdgeInsets padding;

  const RelativeDateRangePickerHelper({
    super.key,
    required this.field,
    this.onChanged,
    required this.padding,
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
      child: CustomScrollView(
        scrollDirection: Axis.horizontal,
        slivers: [
          SliverToBoxAdapter(child: SizedBox(width: widget.padding.left)),
          SliverList.separated(
            itemCount: _options.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8.0),
            itemBuilder: (context, index) {
              final option = _options[index];
              return ColoredChipWrapper(
                child: FilterChip(
                  label: Text(option.title),
                  onSelected: (isSelected) {
                    final value = isSelected
                        ? option.value
                        : const RelativeDateRangeQuery();
                    widget.field.didChange(value);
                    widget.onChanged?.call(value);
                  },
                  selected: widget.field.value == option.value,
                ),
              );
            },
          ),
          SliverToBoxAdapter(child: SizedBox(width: widget.padding.right))
        ],
      ),
    );
  }

  List<_ExtendedDateRangeQueryOption> get _options => [
        _ExtendedDateRangeQueryOption(
          S.of(context)!.lastNWeeks(1),
          const RelativeDateRangeQuery(1, DateRangeUnit.week),
        ),
        _ExtendedDateRangeQueryOption(
          S.of(context)!.lastNMonths(1),
          const RelativeDateRangeQuery(1, DateRangeUnit.month),
        ),
        _ExtendedDateRangeQueryOption(
          S.of(context)!.lastNMonths(3),
          const RelativeDateRangeQuery(3, DateRangeUnit.month),
        ),
        _ExtendedDateRangeQueryOption(
          S.of(context)!.lastNYears(1),
          const RelativeDateRangeQuery(1, DateRangeUnit.year),
        ),
      ];
}

class _ExtendedDateRangeQueryOption {
  final String title;
  final RelativeDateRangeQuery value;

  _ExtendedDateRangeQueryOption(this.title, this.value);
}
