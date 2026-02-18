import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/database/tables/local_user_account.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/document_details/view/widgets/archive_serial_number_field.dart';
import 'package:paperless_mobile/features/document_details/view/widgets/details_item.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/core/util/format_helpers.dart';

class DocumentMetaDataWidget extends StatelessWidget {
  final DocumentModel document;
  final DocumentMetaData metaData;
  final double itemSpacing;
  const DocumentMetaDataWidget({
    super.key,
    required this.document,
    required this.metaData,
    required this.itemSpacing,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<LocalUserAccount>().paperlessUser;

    return SliverList.list(
      children: [
        if (currentUser.canEditDocuments)
          ArchiveSerialNumberField(
            document: document,
          ).paddedOnly(bottom: itemSpacing),
        DetailsItem.text(
          DateFormat.yMMMMd(Localizations.localeOf(context).toString())
              .format(document.modified),
          context: context,
          label: S.of(context)!.modifiedAt,
        ).paddedOnly(bottom: itemSpacing),
        DetailsItem.text(
          DateFormat.yMMMMd(Localizations.localeOf(context).toString())
              .format(document.added),
          context: context,
          label: S.of(context)!.addedAt,
        ).paddedOnly(bottom: itemSpacing),
        DetailsItem.text(
          metaData.mediaFilename,
          context: context,
          label: S.of(context)!.mediaFilename,
        ).paddedOnly(bottom: itemSpacing),
        if (document.originalFileName != null)
          DetailsItem.text(
            document.originalFileName!,
            context: context,
            label: S.of(context)!.originalFileName,
          ).paddedOnly(bottom: itemSpacing),
        DetailsItem.text(
          metaData.originalChecksum,
          context: context,
          label: S.of(context)!.originalMD5Checksum,
        ).paddedOnly(bottom: itemSpacing),
        DetailsItem.text(
          formatBytes(metaData.originalSize, 2),
          context: context,
          label: S.of(context)!.originalFileSize,
        ).paddedOnly(bottom: itemSpacing),
        DetailsItem.text(
          metaData.originalMimeType,
          context: context,
          label: S.of(context)!.originalMIMEType,
        ).paddedOnly(bottom: itemSpacing),
      ],
    );
  }
}
