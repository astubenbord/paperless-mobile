import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/database/hive/hive_config.dart';
import 'package:paperless_mobile/core/database/tables/local_user_account.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/document_details/cubit/document_details_cubit.dart';
import 'package:paperless_mobile/features/document_details/view/dialogs/select_file_type_dialog.dart';
import 'package:paperless_mobile/core/database/tables/global_settings.dart';
import 'package:paperless_mobile/core/model/file_download_type.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

import 'package:paperless_mobile/helpers/message_helpers.dart';
import 'package:paperless_mobile/helpers/permission_helpers.dart';
import 'package:paperless_mobile/core/global/constants.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

class DocumentDownloadButton extends StatefulWidget {
  final DocumentModel? document;
  final bool enabled;
  const DocumentDownloadButton({
    super.key,
    required this.document,
    this.enabled = true,
  });

  @override
  State<DocumentDownloadButton> createState() => _DocumentDownloadButtonState();
}

class _DocumentDownloadButtonState extends State<DocumentDownloadButton> {
  bool _isDownloadPending = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: S.of(context)!.downloadDocumentTooltip,
      icon: _isDownloadPending
          ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(),
            )
          : const Icon(Icons.download),
      onPressed: widget.document != null && widget.enabled
          ? () => _onDownload(widget.document!)
          : null,
    ).paddedOnly(right: 4);
  }

  Future<void> _onDownload(DocumentModel document) async {
    try {
      final globalSettings =
          Hive.box<GlobalSettings>(HiveBoxes.globalSettings).getValue()!;
      bool original;

      switch (globalSettings.defaultDownloadType) {
        case FileDownloadType.original:
          original = true;
          break;
        case FileDownloadType.archived:
          original = false;
          break;
        case FileDownloadType.alwaysAsk:
          final isOriginal = await showDialog<bool>(
            context: context,
            builder: (context) => SelectFileTypeDialog(
              onRememberSelection: (downloadType) {
                globalSettings.defaultDownloadType = downloadType;
                globalSettings.save();
              },
            ),
          );
          if (isOriginal == null) {
            return;
          } else {
            original = isOriginal;
          }
          break;
      }

      if (Platform.isAndroid && androidInfo!.version.sdkInt <= 29) {
        final isGranted = await askForPermission(Permission.storage);
        if (!isGranted) {
          return;
          //TODO: Ask user to grant permissions
        }
      }

      setState(() => _isDownloadPending = true);
      if (mounted) {
        final userId = context.read<LocalUserAccount>().id;
        await context.read<DocumentDetailsCubit>().downloadDocument(
              downloadOriginal: original,
              locale: globalSettings.preferredLocaleSubtag,
              userId: userId,
            );
        // showSnackBar(context, S.of(context)!.documentSuccessfullyDownloaded);
      }
    } on PaperlessApiException catch (error, stackTrace) {
      if (mounted) showErrorMessage(context, error, stackTrace);
    } catch (error) {
      if (mounted) showGenericError(context, error);
    } finally {
      if (mounted) setState(() => _isDownloadPending = false);
    }
  }
}
