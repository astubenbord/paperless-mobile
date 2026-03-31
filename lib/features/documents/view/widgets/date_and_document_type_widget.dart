import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:paperless_mobile/api/models/document.dart';
import 'package:paperless_mobile/core/extensions/context_extensions.dart';

class DateAndDocumentTypeLabelWidget extends StatelessWidget {
  const DateAndDocumentTypeLabelWidget({
    super.key,
    required this.document,
    required this.onDocumentTypeSelected,
  });

  final Document document;
  final void Function(int? documentTypeId)? onDocumentTypeSelected;

  @override
  Widget build(BuildContext context) {
    final subtitleStyle = Theme.of(
      context,
    ).textTheme.labelMedium?.apply(color: Colors.grey);

    final dateText = document.created != null
        ? context.displayDateFormat.format(document.created!)
        : null;
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        text: dateText,
        style: subtitleStyle,
        children: document.documentType != null
            ? [
                const TextSpan(text: '\u30FB'),
                WidgetSpan(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: onDocumentTypeSelected != null
                          ? () => onDocumentTypeSelected!(document.documentType)
                          : null,
                      child: QueryBuilder(
                        query: context.documentTypeRepository.getAllQuery(),
                        builder: (context, state) {
                          final documentType = state.data?.firstWhereOrNull(
                            (dt) => dt.id == document.documentType,
                          );
                          return Text(
                            documentType?.name ?? '',
                            style: subtitleStyle,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ]
            : null,
      ),
    );
  }
}
