import 'package:flutter/material.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/features/documents/view/widgets/document_preview.dart';
import 'package:paperless_mobile/features/labels/correspondent/view/widgets/correspondent_widget.dart';
import 'package:paperless_mobile/features/labels/document_type/view/widgets/document_type_widget.dart';
import 'package:paperless_mobile/features/labels/tags/view/widgets/tags_widget.dart';
import 'package:intl/intl.dart';

class DocumentGridItem extends StatelessWidget {
  final DocumentModel document;
  final bool isSelected;
  final void Function(DocumentModel) onTap;
  final void Function(DocumentModel) onSelected;
  final bool isAtLeastOneSelected;
  final bool Function(int tagId) isTagSelectedPredicate;
  final void Function(int tagId) onTagSelected;

  const DocumentGridItem({
    Key? key,
    required this.document,
    required this.onTap,
    required this.onSelected,
    required this.isSelected,
    required this.isAtLeastOneSelected,
    required this.isTagSelectedPredicate,
    required this.onTagSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      onLongPress: () => onSelected(document),
      child: AbsorbPointer(
        absorbing: isAtLeastOneSelected,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            elevation: 1.0,
            color: isSelected
                ? Theme.of(context).colorScheme.inversePrimary
                : Theme.of(context).cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: DocumentPreview(
                    id: document.id,
                    borderRadius: 12.0,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CorrespondentWidget(
                            correspondentId: document.correspondent),
                        DocumentTypeWidget(
                            documentTypeId: document.documentType),
                        Text(
                          document.title,
                          maxLines: document.tags.isEmpty ? 3 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        TagsWidget(
                          tagIds: document.tags,
                          isMultiLine: false,
                          isSelectedPredicate: isTagSelectedPredicate,
                          onTagSelected: onTagSelected,
                        ),
                        const Spacer(),
                        Text(
                          DateFormat.yMMMd().format(
                            document.created,
                          ),
                          style: Theme.of(context).textTheme.caption,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTap() {
    if (isAtLeastOneSelected || isSelected) {
      onSelected(document);
    } else {
      onTap(document);
    }
  }
}
