import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/database/tables/local_user_account.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/core/widgets/highlighted_text.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/document_details/view/widgets/details_item.dart';
import 'package:paperless_mobile/features/document_details/view/widgets/document_custom_fields_widget.dart';
import 'package:paperless_mobile/features/labels/tags/view/widgets/tags_widget.dart';
import 'package:paperless_mobile/features/labels/view/widgets/label_text.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class DocumentOverviewWidget extends StatelessWidget {
  final DocumentModel document;
  final String? queryString;
  final double itemSpacing;

  const DocumentOverviewWidget({
    super.key,
    required this.document,
    this.queryString,
    required this.itemSpacing,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.watch<LocalUserAccount>().paperlessUser;
    final labelRepository = context.watch<LabelRepository>();

    return SliverList.list(
      children: [
        if (document.title.isNotEmpty)
          DetailsItem(
            label: S.of(context)!.title,
            content: HighlightedText(
              text: document.title,
              highlights: queryString?.split(" ") ?? [],
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ).paddedOnly(bottom: itemSpacing),
        DetailsItem.text(
          DateFormat.yMMMMd(Localizations.localeOf(context).toString())
              .format(document.created),
          context: context,
          label: S.of(context)!.createdAt,
        ).paddedOnly(bottom: itemSpacing),
        if (document.documentType != null && user.canViewDocumentTypes)
          DetailsItem(
            label: S.of(context)!.documentType,
            content: LabelText<DocumentType>(
              style: Theme.of(context).textTheme.bodyLarge,
              label: labelRepository.documentTypes[document.documentType],
            ),
          ).paddedOnly(bottom: itemSpacing),
        if (document.correspondent != null && user.canViewCorrespondents)
          DetailsItem(
            label: S.of(context)!.correspondent,
            content: LabelText<Correspondent>(
              style: Theme.of(context).textTheme.bodyLarge,
              label: labelRepository.correspondents[document.correspondent],
            ),
          ).paddedOnly(bottom: itemSpacing),
        if (document.storagePath != null && user.canViewStoragePaths)
          DetailsItem(
            label: S.of(context)!.storagePath,
            content: LabelText<StoragePath>(
              label: labelRepository.storagePaths[document.storagePath],
            ),
          ).paddedOnly(bottom: itemSpacing),
        if (document.tags.isNotEmpty && user.canViewTags)
          DetailsItem(
            label: S.of(context)!.tags,
            content: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: TagsWidget(
                isClickable: false,
                tags:
                    document.tags.map((e) => labelRepository.tags[e]!).toList(),
              ),
            ),
          ).paddedOnly(bottom: itemSpacing),
        if (document.customFields.isNotEmpty)
          DocumentCustomFieldsWidget(
            document: document,
            itemSpacing: itemSpacing,
          ).paddedOnly(bottom: itemSpacing),
      ],
    );
  }
}
