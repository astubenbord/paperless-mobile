import 'package:flutter/material.dart';
import 'package:paperless_mobile/features/documents/model/document.model.dart';
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

  const DocumentListItem({
    Key? key,
    required this.document,
    required this.onTap,
    this.onSelected,
    required this.isSelected,
    required this.isAtLeastOneSelected,
    this.isLabelClickable = true,
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
