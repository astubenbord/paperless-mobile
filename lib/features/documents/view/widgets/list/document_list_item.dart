import 'package:flutter/material.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/features/documents/view/widgets/document_preview.dart';
import 'package:paperless_mobile/features/labels/correspondent/view/widgets/correspondent_widget.dart';
import 'package:paperless_mobile/features/labels/tags/view/widgets/tags_widget.dart';

class DocumentListItem extends StatelessWidget {
  static const _a4AspectRatio = 1 / 1.4142;
  final DocumentModel document;
  final void Function(DocumentModel) onTap;
  final void Function(DocumentModel)? onSelected;
  final bool isSelected;
  final bool isAtLeastOneSelected;
  final bool isLabelClickable;
  final bool Function(int tagId) isTagSelectedPredicate;

  final void Function(int tagId)? onTagSelected;
  final void Function(int? correspondentId)? onCorrespondentSelected;
  final void Function(int? documentTypeId)? onDocumentTypeSelected;
  final void Function(int? id)? onStoragePathSelected;

  const DocumentListItem({
    Key? key,
    required this.document,
    required this.onTap,
    this.onSelected,
    required this.isSelected,
    required this.isAtLeastOneSelected,
    this.isLabelClickable = true,
    required this.isTagSelectedPredicate,
    this.onTagSelected,
    this.onCorrespondentSelected,
    this.onDocumentTypeSelected,
    this.onStoragePathSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: ListTile(
        dense: true,
        selected: isSelected,
        onTap: () => _onTap(),
        selectedTileColor: Theme.of(context).colorScheme.inversePrimary,
        onLongPress: () => onSelected?.call(document),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Row(
              children: [
                AbsorbPointer(
                  absorbing: isAtLeastOneSelected,
                  child: CorrespondentWidget(
                    isClickable: isLabelClickable,
                    correspondentId: document.correspondent,
                    onSelected: onCorrespondentSelected,
                  ),
                ),
              ],
            ),
            Text(
              document.title,
              overflow: TextOverflow.ellipsis,
              maxLines: document.tags.isEmpty ? 2 : 1,
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: AbsorbPointer(
            absorbing: isAtLeastOneSelected,
            child: TagsWidget(
              isClickable: isLabelClickable,
              tagIds: document.tags,
              isMultiLine: false,
              isSelectedPredicate: isTagSelectedPredicate,
              onTagSelected: (id) => onTagSelected?.call(id),
            ),
          ),
        ),
        isThreeLine: document.tags.isNotEmpty,
        leading: AspectRatio(
          aspectRatio: _a4AspectRatio,
          child: GestureDetector(
            child: DocumentPreview(
              id: document.id,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
        ),
        contentPadding: const EdgeInsets.all(8.0),
      ),
    );
  }

  void _onTap() {
    if (isAtLeastOneSelected || isSelected) {
      onSelected?.call(document);
    } else {
      onTap(document);
    }
  }
}
