import 'package:flutter/material.dart';
import 'package:paperless_api/paperless_api.dart';

class CorrespondentWidget extends StatelessWidget {
  final Correspondent? correspondent;
  final void Function(int? id)? onSelected;
  final Color? textColor;
  final bool isClickable;
  final TextStyle? textStyle;

  const CorrespondentWidget({
    super.key,
    required this.correspondent,
    this.textColor,
    this.isClickable = true,
    this.textStyle,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: !isClickable,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () => onSelected?.call(correspondent?.id),
          child: Text(
            correspondent?.name ?? "-",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                (textStyle ?? Theme.of(context).textTheme.bodyMedium)?.copyWith(
              color: textColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
