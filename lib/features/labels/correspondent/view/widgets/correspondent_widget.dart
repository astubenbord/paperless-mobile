import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:flutter/material.dart';
import 'package:paperless_mobile/api/paperless_api.dart';
import 'package:paperless_mobile/core/extensions/context_extensions.dart';
import 'package:paperless_mobile/core/extensions/label_list_extension.dart';

class CorrespondentWidget extends StatelessWidget {
  final int? id;
  final void Function(int? id)? onSelected;
  final Color? textColor;
  final bool isClickable;
  final TextStyle? textStyle;

  const CorrespondentWidget({
    super.key,
    required this.id,
    this.textColor,
    this.isClickable = true,
    this.textStyle,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (!context.uiSettings$.canViewCorrespondents) {
      return SizedBox.shrink();
    }
    return QueryBuilder(
      query: context.correspondentRepository.getAllQuery(),
      builder: (context, state) => AbsorbPointer(
        absorbing: !isClickable,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () => onSelected?.call(id),
            child: Text(
              state.data?.toIdMap()[id]?.name ?? "-",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (textStyle ?? Theme.of(context).textTheme.bodyMedium)
                  ?.copyWith(
                    color: textColor ?? Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
