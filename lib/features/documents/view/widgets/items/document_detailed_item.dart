import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/database/hive/hive_config.dart';
import 'package:paperless_mobile/core/database/tables/global_settings.dart';
import 'package:paperless_mobile/core/database/tables/local_user_account.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/features/documents/view/widgets/date_and_document_type_widget.dart';
import 'package:paperless_mobile/features/documents/view/widgets/document_preview.dart';
import 'package:paperless_mobile/features/documents/view/widgets/items/document_item.dart';
import 'package:paperless_mobile/features/labels/correspondent/view/widgets/correspondent_widget.dart';
import 'package:paperless_mobile/features/labels/tags/view/widgets/tags_widget.dart';
import 'package:provider/provider.dart';

class DocumentDetailedItem extends DocumentItem {
  final String? highlights;
  const DocumentDetailedItem({
    super.key,
    this.highlights,
    required super.document,
    required super.isSelected,
    required super.isSelectionActive,
    required super.isLabelClickable,
    required super.enableHeroAnimation,
    super.onCorrespondentSelected,
    super.onDocumentTypeSelected,
    super.onSelected,
    super.onStoragePathSelected,
    super.onTagSelected,
    super.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = Hive.box<GlobalSettings>(HiveBoxes.globalSettings)
        .getValue()!
        .loggedInUserId;
    final paperlessUser = Hive.box<LocalUserAccount>(HiveBoxes.localUserAccount)
        .get(currentUserId)!
        .paperlessUser;
    final size = MediaQuery.of(context).size;
    final insets = MediaQuery.of(context).viewInsets;
    final padding = MediaQuery.of(context).viewPadding;
    final availableHeight = size.height -
        insets.top -
        insets.bottom -
        padding.top -
        padding.bottom -
        kBottomNavigationBarHeight -
        kToolbarHeight;
    final maxHeight = highlights != null
        ? min(600.0, availableHeight)
        : min(500.0, availableHeight);
    final labelRepository = context.watch<LabelRepository>();
    return Card(
      color: isSelected ? Theme.of(context).colorScheme.inversePrimary : null,
      child: InkWell(
        enableFeedback: true,
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (isSelectionActive) {
            onSelected?.call(document);
          } else {
            onTap?.call(document);
          }
        },
        onLongPress: () {
          onSelected?.call(document);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints.tightFor(
                width: double.infinity,
                height: maxHeight / 2,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DocumentPreview(
                    documentId: document.id,
                    title: document.title,
                  ),
                  if (paperlessUser.canViewTags)
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: TagsWidget(
                        tags: document.tags
                            .where((e) => labelRepository.tags.containsKey(e))
                            .map((e) => labelRepository.tags[e]!)
                            .toList(),
                        onTagSelected: onTagSelected,
                      ).padded(),
                    ),
                ],
              ),
            ),
            if (paperlessUser.canViewCorrespondents)
              CorrespondentWidget(
                onSelected: onCorrespondentSelected,
                textStyle: Theme.of(context).textTheme.titleSmall?.apply(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                correspondent:
                    labelRepository.correspondents[document.correspondent],
              ).paddedLTRB(8, 8, 8, 0),
            Text(
              document.title.isEmpty ? '(-)' : document.title,
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ).paddedLTRB(8, 8, 8, 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DateAndDocumentTypeLabelWidget(
                    document: document,
                    onDocumentTypeSelected: onDocumentTypeSelected,
                  ),
                ),
                if (document.archiveSerialNumber != null)
                  Text(
                    '#${document.archiveSerialNumber}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.apply(color: Theme.of(context).hintColor),
                  ),
              ],
            ).paddedLTRB(8, 4, 8, 8),
            if (highlights != null)
              Html(
                data: '<p>${highlights!}</p>',
                style: {
                  "span": Style(
                    backgroundColor: Colors.yellow,
                    color: Colors.black,
                  ),
                  "p": Style(
                    maxLines: 3,
                    textOverflow: TextOverflow.ellipsis,
                  ),
                },
              ).padded(),
          ],
        ),
      ),
    ).padded();
  }
}
