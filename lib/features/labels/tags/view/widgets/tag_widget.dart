import 'package:flutter/material.dart';
import 'package:paperless_api/paperless_api.dart';

class TagWidget extends StatelessWidget {
  final Tag tag;
  final VoidCallback? afterTagTapped;
  final VoidCallback onSelected;
  final bool isSelected;
  final bool isClickable;

  const TagWidget({
    super.key,
    required this.tag,
    required this.afterTagTapped,
    this.isClickable = true,
    required this.onSelected,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4.0),
      child: AbsorbPointer(
        absorbing: !isClickable,
        child: FilterChip(
          selected: isSelected,
          selectedColor: tag.color,
          onSelected: (_) => onSelected(),
          visualDensity: const VisualDensity(vertical: -2),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          label: Text(
            tag.name,
            style: TextStyle(color: tag.textColor),
          ),
          checkmarkColor: tag.textColor,
          backgroundColor: tag.color,
          side: BorderSide.none,
        ),
      ),
    );
  }
}
