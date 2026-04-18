import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:flutter/material.dart';
import 'package:paperless_mobile/api/extensions/cached_query_extensions.dart';
import 'package:paperless_mobile/api/paperless_api.dart';
import 'package:paperless_mobile/core/extensions/context_extensions.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/document_details/view/widgets/archive_serial_number_field.dart';
import 'package:paperless_mobile/features/document_details/view/widgets/details_item.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/helpers/format_helpers.dart';

class DocumentMetaDataWidget extends StatelessWidget {
  final Document document;
  final double itemSpacing;

  const DocumentMetaDataWidget({
    super.key,
    required this.document,
    required this.itemSpacing,
  });

  @override
  Widget build(BuildContext context) {
    final uiSettings = context.loggedInUser$.profile.uiSettings;
    return QueryBuilder(
      query: context.documentRepository.getMetaDataQuery(document.id),
      builder: (context, state) {
        if (state.isLoadingInitial) {
          return SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.isError) {
          return SliverToBoxAdapter(
            child: Center(
              child: Text(
                S
                    .of(context)!
                    .anUnknownErrorOccurred, //TODO: INTL better error message
                textAlign: TextAlign.center,
              ),
            ).padded(),
          );
        }

        final metadata = state.data!;
        return SliverList.list(
          children: [
            if (uiSettings.canEditDocuments)
              ArchiveSerialNumberField(
                key: ValueKey(
                  'asn_field_${document.id}_${document.archiveSerialNumber}',
                ),
                documentId: document.id,
                initialValue: document.archiveSerialNumber,
              ).paddedOnly(bottom: itemSpacing),
            if (document.modified != null)
              DetailsItem.text(
                context.displayDateFormat.format(document.modified!),
                context: context,
                label: S.of(context)!.modifiedAt,
              ).paddedOnly(bottom: itemSpacing),
            if (document.added != null)
              DetailsItem.text(
                context.displayDateFormat.format(document.added!),
                context: context,
                label: S.of(context)!.addedAt,
              ).paddedOnly(bottom: itemSpacing),
            DetailsItem.text(
              metadata.mediaFilename,
              context: context,
              label: S.of(context)!.mediaFilename,
            ).paddedOnly(bottom: itemSpacing),
            if (document.originalFileName != null)
              DetailsItem.text(
                document.originalFileName!,
                context: context,
                label: S.of(context)!.originalFilename,
              ).paddedOnly(bottom: itemSpacing),
            DetailsItem.text(
              metadata.originalChecksum,
              context: context,
              label: S.of(context)!.originalMD5Checksum,
            ).paddedOnly(bottom: itemSpacing),
            DetailsItem.text(
              metadata.originalSize != null
                  ? formatBytes(metadata.originalSize!, 2)
                  : '-',
              context: context,
              label: S.of(context)!.originalFileSize,
            ).paddedOnly(bottom: itemSpacing),
            DetailsItem.text(
              metadata.originalMimeType,
              context: context,
              label: S.of(context)!.originalMIMEType,
            ).paddedOnly(bottom: itemSpacing),
          ],
        );
      },
    );
  }
}
