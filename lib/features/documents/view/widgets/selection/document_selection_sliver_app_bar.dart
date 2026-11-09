import 'dart:io';

import 'package:flutter/material.dart';
import 'package:paperless_mobile/api/paperless_api.dart';
import 'package:paperless_mobile/constants.dart';
import 'package:paperless_mobile/core/extensions/context_extensions.dart';
import 'package:paperless_mobile/core/extensions/document_extensions.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/core/service/file_service.dart';
import 'package:paperless_mobile/core/store/slices/global_settings.dart';
import 'package:paperless_mobile/core/widgets/icon_loading_widget.dart';
import 'package:paperless_mobile/features/document_details/view/dialogs/select_file_type_dialog.dart';
import 'package:paperless_mobile/features/documents/view/widgets/selection/bulk_delete_confirmation_dialog.dart';
import 'package:paperless_mobile/features/documents/view/widgets/selection/bulk_download_target_directory_dialog.dart';
import 'package:paperless_mobile/features/settings/model/file_download_type.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/helpers/message_helpers.dart';
import 'package:paperless_mobile/helpers/permission_helpers.dart';
import 'package:paperless_mobile/routing/routes/documents_route.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class DocumentSelectionSliverAppBar extends StatefulWidget {
  final Iterable<Document> selection;
  final VoidCallback onResetSelection;
  const DocumentSelectionSliverAppBar({
    super.key,
    required this.selection,
    required this.onResetSelection,
  });

  @override
  State<DocumentSelectionSliverAppBar> createState() =>
      _DocumentSelectionSliverAppBarState();
}

class _DocumentSelectionSliverAppBarState
    extends State<DocumentSelectionSliverAppBar> {
  bool _isBusy = false;

  @override
  Widget build(BuildContext context) {
    final selection = widget.selection.toList(growable: false);
    return SliverAppBar(
      stretch: false,
      pinned: true,
      floating: true,
      snap: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      title: Text(S.of(context)!.countSelected(selection.length)),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _isBusy ? null : widget.onResetSelection,
      ),
      actions: [
        IconButton(
          tooltip: S.of(context)!.shareTooltip,
          icon: const Icon(Icons.share),
          onPressed: _isBusy ? null : () => _onShareSelection(selection),
        ),
        IconButton(
          tooltip: S.of(context)!.downloadDocumentTooltip,
          icon: const Icon(Icons.download),
          onPressed: _isBusy ? null : () => _onDownloadSelection(selection),
        ),
        IconButton(
          tooltip: S.of(context)!.delete,
          icon: const Icon(Icons.delete),
          onPressed: _isBusy ? null : () => _onDeleteSelection(selection),
        ),
        if (_isBusy)
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: IconLoadingWidget(),
              ),
            ),
          ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(kTextTabBarHeight),
        child: SizedBox(
          height: kTextTabBarHeight,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ActionChip(
                label: Text(S.of(context)!.correspondent),
                avatar: const Icon(Icons.edit),
                onPressed: () {
                  BulkEditDocumentsRoute(
                    BulkEditExtraWrapper(
                      widget.selection,
                      LabelType.correspondent,
                    ),
                  ).push<bool>(context).then((wasSuccessful) {
                    if (wasSuccessful ?? false) {
                      widget.onResetSelection();
                    }
                  });
                },
              ).paddedOnly(left: 8, right: 4),
              ActionChip(
                label: Text(S.of(context)!.documentType),
                avatar: const Icon(Icons.edit),
                onPressed: () async {
                  BulkEditDocumentsRoute(
                    BulkEditExtraWrapper(
                      widget.selection,
                      LabelType.documentType,
                    ),
                  ).push<bool>(context).then((wasSuccessful) {
                    if (wasSuccessful ?? false) {
                      widget.onResetSelection();
                    }
                  });
                },
              ).paddedOnly(left: 8, right: 4),
              ActionChip(
                label: Text(S.of(context)!.storagePath),
                avatar: const Icon(Icons.edit),
                onPressed: () async {
                  BulkEditDocumentsRoute(
                    BulkEditExtraWrapper(
                      widget.selection,
                      LabelType.storagePath,
                    ),
                  ).push<bool>(context).then((wasSuccessful) {
                    if (wasSuccessful ?? false) {
                      widget.onResetSelection();
                    }
                  });
                },
              ).paddedOnly(left: 8, right: 4),
              _buildBulkEditTagsChip(context).paddedOnly(left: 4, right: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBulkEditTagsChip(BuildContext context) {
    return ActionChip(
      label: Text(S.of(context)!.tags),
      avatar: const Icon(Icons.edit),
      onPressed: () {
        BulkEditDocumentsRoute(
          BulkEditExtraWrapper(widget.selection, LabelType.tag),
        ).push<bool>(context).then((wasSuccessful) {
          if (wasSuccessful ?? false) {
            widget.onResetSelection();
          }
        });
      },
    );
  }

  Future<void> _onDeleteSelection(List<Document> selection) async {
    final bulkDelete = context.documentRepository.bulkActionMutation().mutate;

    final shouldDelete =
        await showDialog<bool>(
          useRootNavigator: false,
          context: context,
          builder: (context) =>
              BulkDeleteConfirmationDialog(selection: selection),
        ) ??
        false;
    if (!shouldDelete || !mounted) {
      return;
    }

    await _runBusyAction(() async {
      try {
        await bulkDelete(
          BulkEditRequest(documents: selection.ids, method: MethodEnum.delete),
        );
        if (!mounted) return;
        showSnackBar(context, S.of(context)!.documentsSuccessfullyDeleted);
        widget.onResetSelection();
      } on PaperlessApiException catch (error, stackTrace) {
        if (!mounted) return;
        showErrorMessage(context, error, stackTrace);
      }
    });
  }

  Future<void> _onShareSelection(List<Document> selection) async {
    if (selection.isEmpty) return;

    try {
      final shareOriginal = await _resolveFileTypeSelection(forSharing: true);
      if (shareOriginal == null || !mounted) {
        return;
      }
      final hasPermission = await _ensureStoragePermission(forSharing: true);
      if (!hasPermission || !mounted) {
        return;
      }
      await _runBusyAction(() async {
        final downloads = await _downloadDocuments(
          documents: selection,
          targetDirectoryPath: FileService.instance.temporaryDirectory.path,
          original: shareOriginal,
        );
        if (downloads.isEmpty) {
          return;
        }
        await SharePlus.instance.share(
          ShareParams(
            files: downloads
                .map(
                  (download) => XFile(
                    download.file.path,
                    name: p.basename(download.file.path),
                    mimeType: shareOriginal
                        ? download.document.mimeType
                        : 'application/pdf',
                    lastModified: download.document.modified,
                  ),
                )
                .toList(),
            subject: selection.length == 1 ? selection.first.title : null,
          ),
        );
      });
    } on PaperlessApiException catch (error, stackTrace) {
      if (!mounted) return;
      showErrorMessage(context, error, stackTrace);
    } catch (error) {
      if (!mounted) return;
      showGenericError(context, error);
    }
  }

  Future<void> _onDownloadSelection(List<Document> selection) async {
    if (selection.isEmpty) return;

    try {
      final downloadOriginal = await _resolveFileTypeSelection(
        forSharing: false,
      );
      if (downloadOriginal == null || !mounted) {
        return;
      }
      final hasPermission = await _ensureStoragePermission(forSharing: false);
      if (!hasPermission || !mounted) {
        return;
      }
      String defaultDirectory = '/storage/emulated/0/Download';
      try {
        defaultDirectory = await _resolveDefaultDownloadDirectory();
      } on Exception {
        // Keep fallback path.
      }
      if (!mounted) {
        return;
      }
      final targetDirectoryPath = await showDialog<String>(
        useRootNavigator: false,
        context: context,
        builder: (context) => BulkDownloadTargetDirectoryDialog(
          documentsCount: selection.length,
          initialDirectoryPath: defaultDirectory,
        ),
      );
      if (targetDirectoryPath == null || !mounted) {
        return;
      }

      await _runBusyAction(() async {
        await _downloadDocuments(
          documents: selection,
          targetDirectoryPath: targetDirectoryPath,
          original: downloadOriginal,
        );
      });
      if (!mounted) return;
      showSnackBar(context, S.of(context)!.notificationDownloadComplete);
    } on PaperlessApiException catch (error, stackTrace) {
      if (!mounted) return;
      showErrorMessage(context, error, stackTrace);
    } catch (error) {
      if (!mounted) return;
      showGenericError(context, error);
    }
  }

  Future<bool?> _resolveFileTypeSelection({required bool forSharing}) async {
    final localStore = context.localStore;
    final defaultType = forSharing
        ? localStore.state.globalSettings.defaultShareType
        : localStore.state.globalSettings.defaultDownloadType;
    return switch (defaultType) {
      FileDownloadType.original => true,
      FileDownloadType.archived => false,
      FileDownloadType.alwaysAsk => showDialog<bool>(
        useRootNavigator: false,
        context: context,
        builder: (dialogContext) => SelectFileTypeDialog(
          onRememberSelection: (downloadType) {
            localStore.updateGlobalSettings(
              (globalSettings) => forSharing
                  ? globalSettings.copyWith(defaultShareType: downloadType)
                  : globalSettings.copyWith(defaultDownloadType: downloadType),
            );
          },
        ),
      ),
    };
  }

  Future<bool> _ensureStoragePermission({required bool forSharing}) async {
    if (!Platform.isAndroid) {
      return true;
    }
    final sdkInt = androidInfo?.version.sdkInt;
    if (sdkInt == null) {
      return true;
    }
    final shouldRequestPermission = forSharing ? sdkInt < 30 : sdkInt <= 29;
    if (!shouldRequestPermission) {
      return true;
    }
    return askForPermission(Permission.storage);
  }

  Future<String> _resolveDefaultDownloadDirectory() async {
    return FileService.instance.downloadsDirectory.path;
  }

  Future<List<_DownloadedDocument>> _downloadDocuments({
    required Iterable<Document> documents,
    required String targetDirectoryPath,
    required bool original,
  }) async {
    final api = context.read<PaperlessDocumentsApi>();
    final targetDirectory = Directory(targetDirectoryPath);
    await targetDirectory.create(recursive: true);

    final downloadedDocuments = <_DownloadedDocument>[];
    for (final document in documents) {
      final targetPath = await _buildUniqueTargetPath(
        document: document,
        parentDirectoryPath: targetDirectory.path,
        original: original,
      );
      await api.downloadToFile(document.id, targetPath, original: original);
      downloadedDocuments.add(_DownloadedDocument(document, File(targetPath)));
    }
    return downloadedDocuments;
  }

  Future<String> _buildUniqueTargetPath({
    required Document document,
    required String parentDirectoryPath,
    required bool original,
  }) async {
    final preferredFilename = _sanitizeFilename(
      document.archivedFileName ??
          document.originalFileName ??
          document.title ??
          'document_${document.id}',
    );

    final baseName = p.basenameWithoutExtension(preferredFilename).trim();
    final normalizedBaseName = baseName.isEmpty
        ? 'document_${document.id}'
        : baseName;
    final extension = original ? p.extension(preferredFilename) : '.pdf';
    final normalizedExtension = extension.isEmpty
        ? (original ? '.bin' : '.pdf')
        : extension;

    var candidate = p.join(
      parentDirectoryPath,
      '$normalizedBaseName$normalizedExtension',
    );
    var copy = 1;
    while (await File(candidate).exists()) {
      candidate = p.join(
        parentDirectoryPath,
        '${normalizedBaseName}_$copy$normalizedExtension',
      );
      copy += 1;
    }
    return candidate;
  }

  String _sanitizeFilename(String input) {
    return input
        .replaceAll(RegExp(r'[/\\]'), ' ')
        .replaceAll(RegExp(r'[:*?"<>|]'), '_')
        .trim();
  }

  Future<void> _runBusyAction(Future<void> Function() action) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }
}

class _DownloadedDocument {
  final Document document;
  final File file;

  const _DownloadedDocument(this.document, this.file);
}
