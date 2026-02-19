import 'package:flutter/material.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/features/documents/view/widgets/date_and_document_type_widget.dart';
import 'package:paperless_mobile/features/documents/view/widgets/document_preview.dart';
import 'package:paperless_mobile/features/documents/view/widgets/items/document_item.dart';
import 'package:paperless_mobile/features/labels/correspondent/view/widgets/correspondent_widget.dart';
import 'package:paperless_mobile/features/labels/tags/view/widgets/tags_widget.dart';
import 'package:provider/provider.dart';

class DocumentListItem extends DocumentItem {
  final Color? backgroundColor;
  const DocumentListItem({
    super.key,
    this.backgroundColor,
    required super.document,
    required super.isSelected,
    required super.isSelectionActive,
    required super.isLabelClickable,
    super.onCorrespondentSelected,
    super.onDocumentTypeSelected,
    super.onSelected,
    super.onStoragePathSelected,
    super.onTagSelected,
    super.onTap,
    super.enableHeroAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    final labelRepository = context.watch<LabelRepository>();

    return Card(
      elevation: 0,
      color: isSelected
          ? Theme.of(context).colorScheme.secondaryContainer
          : backgroundColor,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _onTap(),
        onLongPress: onSelected != null ? () => onSelected!(document) : null,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 56,
                  height: 80,
                  child: DocumentPreview(
                    documentId: document.id,
                    title: document.title,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    enableHero: enableHeroAnimation,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title.isEmpty ? '-' : document.title,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (document.archiveSerialNumber != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .tertiaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '#${document.archiveSerialNumber}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onTertiaryContainer,
                                  ),
                            ),
                          ),
                        Flexible(
                          child: AbsorbPointer(
                            absorbing: isSelectionActive,
                            child: CorrespondentWidget(
                              isClickable: isLabelClickable,
                              correspondent: labelRepository
                                  .correspondents[document.correspondent],
                              onSelected: onCorrespondentSelected,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    AbsorbPointer(
                      absorbing: isSelectionActive,
                      child: TagsWidget(
                        isClickable: isLabelClickable,
                        tags: document.tags
                            .where(
                                (e) => labelRepository.tags.containsKey(e))
                            .map((e) => labelRepository.tags[e]!)
                            .toList(),
                        onTagSelected: (id) => onTagSelected?.call(id),
                      ),
                    ),
                    const SizedBox(height: 4),
                    DateAndDocumentTypeLabelWidget(
                      document: document,
                      onDocumentTypeSelected: onDocumentTypeSelected,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTap() {
    if (isSelectionActive || isSelected) {
      onSelected?.call(document);
    } else {
      onTap?.call(document);
    }
  }
}
