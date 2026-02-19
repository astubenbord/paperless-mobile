import 'package:flutter/material.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/widgets/colored_chip.dart';

class TagWidget extends StatelessWidget {
  final Tag tag;
  final VoidCallback onSelected;
  final bool isClickable;
  final bool showShortName;
  final bool dense;

  const TagWidget({
    super.key,
    required this.tag,
    this.isClickable = true,
    required this.onSelected,
    this.showShortName = false,
    this.dense = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4.0),
      child: AbsorbPointer(
        absorbing: !isClickable,
        child: ColoredChipWrapper(
          child: FilterChip(
            labelPadding:
                dense ? const EdgeInsets.symmetric(horizontal: 2) : null,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            selectedColor: tag.color,
            onSelected: (_) => onSelected(),
            visualDensity: const VisualDensity(vertical: -2),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            label: Text(
              showShortName && tag.name.length > 8
                  ? '${tag.name.substring(0, 8)}...'
                  : tag.name,
              style: TextStyle(
                color: tag.textColor,
                fontSize: Theme.of(context).textTheme.labelMedium?.fontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
            checkmarkColor: tag.textColor,
            backgroundColor: tag.color,
            side: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
