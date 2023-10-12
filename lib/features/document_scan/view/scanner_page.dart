import 'dart:developer' as dev;
import 'dart:io';
import 'dart:math';

import 'package:edge_detection/edge_detection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/constants.dart';
import 'package:paperless_mobile/core/config/hive/hive_config.dart';
import 'package:paperless_mobile/core/database/tables/global_settings.dart';
import 'package:paperless_mobile/core/global/constants.dart';
import 'package:paperless_mobile/core/service/file_service.dart';
import 'package:paperless_mobile/features/app_drawer/view/app_drawer.dart';
import 'package:paperless_mobile/features/document_scan/cubit/document_scanner_cubit.dart';
import 'package:paperless_mobile/features/document_scan/view/widgets/export_scans_dialog.dart';
import 'package:paperless_mobile/features/document_scan/view/widgets/scanned_image_item.dart';
import 'package:paperless_mobile/features/document_search/view/sliver_search_bar.dart';
import 'package:paperless_mobile/features/document_upload/view/document_upload_preparation_page.dart';
import 'package:paperless_mobile/features/documents/view/pages/document_view.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/helpers/connectivity_aware_action_wrapper.dart';
import 'package:paperless_mobile/helpers/message_helpers.dart';
import 'package:paperless_mobile/helpers/permission_helpers.dart';
import 'package:paperless_mobile/routes/typed/branches/scanner_route.dart';
import 'package:paperless_mobile/routes/typed/shells/authenticated_route.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:sliver_tools/sliver_tools.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({Key? key}) : super(key: key);

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage>
    with SingleTickerProviderStateMixin {
  final SliverOverlapAbsorberHandle searchBarHandle =
      SliverOverlapAbsorberHandle();
  final SliverOverlapAbsorberHandle actionsHandle =
      SliverOverlapAbsorberHandle();

  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: true,
      child: Scaffold(
        drawer: const AppDrawer(),
        floatingActionButton: FloatingActionButton(
          heroTag: "fab_document_edit",
          onPressed: () => _openDocumentScanner(context),
          child: const Icon(Icons.add_a_photo_outlined),
        ),
        body: NestedScrollView(
          floatHeaderSlivers: true,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverOverlapAbsorber(
              handle: searchBarHandle,
              sliver: SliverSearchBar(
                titleText: S.of(context)!.scanner,
              ),
            ),
            SliverOverlapAbsorber(
              handle: actionsHandle,
              sliver: SliverPinnedHeader(
                child: _buildActions(),
              ),
            ),
          ],
          body: BlocBuilder<DocumentScannerCubit, DocumentScannerState>(
            builder: (context, state) {
              return switch (state) {
                InitialDocumentScannerState() => _buildEmptyState(),
                RestoringDocumentScannerState() => Center(
                    child: Text("Restoring..."),
                  ),
                LoadedDocumentScannerState() => _buildImageGrid(state.scans),
                ErrorDocumentScannerState() => Placeholder(),
              };
            },
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return ColoredBox(
      color: Theme.of(context).colorScheme.background,
      child: SizedBox(
        height: kTextTabBarHeight,
        child: BlocBuilder<DocumentScannerCubit, DocumentScannerState>(
          builder: (context, state) {
            return RawScrollbar(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
              interactive: false,
              thumbVisibility: true,
              thickness: 2,
              radius: Radius.circular(2),
              controller: _scrollController,
              child: ListView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                children: [
                  SizedBox(width: 12),
                  TextButton.icon(
                    label: Text(S.of(context)!.previewScan),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
                    ),
                    onPressed: state.scans.isNotEmpty
                        ? () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => DocumentView(
                                  documentBytes: _assembleFileBytes(
                                    state.scans,
                                    forcePdf: true,
                                  ).then((file) => file.bytes),
                                ),
                              ),
                            )
                        : null,
                    icon: const Icon(Icons.visibility_outlined),
                  ),
                  SizedBox(width: 8),
                  TextButton.icon(
                    label: Text(S.of(context)!.clearAll),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
                    ),
                    onPressed:
                        state.scans.isEmpty ? null : () => _reset(context),
                    icon: const Icon(Icons.delete_sweep_outlined),
                  ),
                  SizedBox(width: 8),
                  ConnectivityAwareActionWrapper(
                    offlineBuilder: (context, child) {
                      return TextButton.icon(
                        label: Text(S.of(context)!.upload),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
                        ),
                        onPressed: null,
                        icon: const Icon(Icons.upload_outlined),
                      );
                    },
                    disabled: state.scans.isEmpty,
                    disabledReason: S.of(context)!.noDocumentsScanned,
                    child: TextButton.icon(
                      label: Text(S.of(context)!.upload),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
                      ),
                      onPressed: () =>
                          _onPrepareDocumentUpload(context, state.scans),
                      icon: const Icon(Icons.upload_outlined),
                    ),
                  ),
                  SizedBox(width: 8),
                  TextButton.icon(
                    label: Text(S.of(context)!.export),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
                    ),
                    onPressed: state.scans.isEmpty ? null : _onSaveToFile,
                    icon: const Icon(Icons.save_alt_outlined),
                  ),
                  SizedBox(width: 12),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _onSaveToFile() async {
    final fileName = await showDialog<String>(
      context: context,
      builder: (context) => const ExportScansDialog(),
    );
    if (fileName != null) {
      final cubit = context.read<DocumentScannerCubit>();
      final file = await _assembleFileBytes(
        forcePdf: true,
        context.read<DocumentScannerCubit>().state.scans,
      );
      try {
        final globalSettings =
            Hive.box<GlobalSettings>(HiveBoxes.globalSettings).getValue()!;
        if (Platform.isAndroid && androidInfo!.version.sdkInt <= 29) {
          final isGranted = await askForPermission(Permission.storage);
          if (!isGranted) {
            showSnackBar(
              context,
              "Please grant Paperless Mobile permissions to access your filesystem.",
              action: SnackBarActionConfig(
                label: "OK",
                onPressed: openAppSettings,
              ),
            );
            return;
          }
        }
        await cubit.saveToFile(
          file.bytes,
          "$fileName.pdf",
          globalSettings.preferredLocaleSubtag,
        );
      } catch (error) {
        showGenericError(context, error);
      }
    }
  }

  void _openDocumentScanner(BuildContext context) async {
    final isGranted = await askForPermission(Permission.camera);
    if (!isGranted) {
      return;
    }
    final file = await FileService.allocateTemporaryFile(
      PaperlessDirectoryType.scans,
      extension: 'jpeg',
    );
    if (kDebugMode) {
      dev.log('[ScannerPage] Created temporary file: ${file.path}');
    }

    final success = await EdgeDetection.detectEdge(file.path);
    if (!success) {
      if (kDebugMode) {
        dev.log(
            '[ScannerPage] Scan either not successful or canceled by user.');
      }
      return;
    }
    if (kDebugMode) {
      dev.log('[ScannerPage] Wrote image to temporary file: ${file.path}');
    }
    context.read<DocumentScannerCubit>().addScan(file);
  }

  void _onPrepareDocumentUpload(BuildContext context, List<File> scans) async {
    final file = await _assembleFileBytes(
      scans,
      forcePdf: Hive.box<GlobalSettings>(HiveBoxes.globalSettings)
          .getValue()!
          .enforceSinglePagePdfUpload,
    );
    final uploadResult = await DocumentUploadRoute(
      $extra: file.bytes,
      fileExtension: file.extension,
    ).push<DocumentUploadResult>(context);
    if (uploadResult?.success ?? false) {
      // For paperless version older than 1.11.3, task id will always be null!
      context.read<DocumentScannerCubit>().reset();
      // context
      //     .read<PendingTasksNotifier>()
      //     .listenToTaskChanges(uploadResult!.taskId!);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              S.of(context)!.noDocumentsScannedYet,
              textAlign: TextAlign.center,
            ),
            TextButton(
              child: Text(S.of(context)!.scanADocument),
              onPressed: () => _openDocumentScanner(context),
            ),
            Text(S.of(context)!.or),
            ConnectivityAwareActionWrapper(
              offlineBuilder: (context, child) => TextButton(
                child: Text(S.of(context)!.uploadADocumentFromThisDevice),
                onPressed: null,
              ),
              child: TextButton(
                child: Text(S.of(context)!.uploadADocumentFromThisDevice),
                onPressed: _onUploadFromFilesystem,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid(List<File> scans) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: CustomScrollView(
        slivers: [
          SliverOverlapInjector(handle: searchBarHandle),
          SliverOverlapInjector(handle: actionsHandle),
          SliverGrid.builder(
            itemCount: scans.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1 / sqrt(2),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              return ScannedImageItem(
                file: scans[index],
                onDelete: () async {
                  try {
                    context
                        .read<DocumentScannerCubit>()
                        .removeScan(scans[index]);
                  } on PaperlessApiException catch (error, stackTrace) {
                    showErrorMessage(context, error, stackTrace);
                  }
                },
                index: index,
                totalNumberOfFiles: scans.length,
              );
            },
          ),
        ],
      ),
    );
  }

  void _reset(BuildContext context) {
    try {
      context.read<DocumentScannerCubit>().reset();
    } on PaperlessApiException catch (error, stackTrace) {
      showErrorMessage(context, error, stackTrace);
    }
  }

  void _onUploadFromFilesystem() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions:
          supportedFileExtensions.map((e) => e.replaceAll(".", "")).toList(),
      withData: true,
      allowMultiple: false,
    );
    if (result?.files.single.path != null) {
      final path = result!.files.single.path!;
      final extension = p.extension(path);
      final filename = p.basenameWithoutExtension(path);
      File file = File(path);
      if (!supportedFileExtensions.contains(extension.toLowerCase())) {
        showErrorMessage(
          context,
          const PaperlessApiException(ErrorCode.unsupportedFileFormat),
        );
        return;
      }
      DocumentUploadRoute(
        $extra: file.readAsBytesSync(),
        filename: filename,
        title: filename,
        fileExtension: extension,
      ).push<DocumentUploadResult>(context);
      // if (uploadResult.success && uploadResult.taskId != null) {
      //   context
      //       .read<PendingTasksNotifier>()
      //       .listenToTaskChanges(uploadResult.taskId!);
      // }
    }
  }

  ///
  /// Returns the file bytes of either a single file or multiple images concatenated into a single pdf.
  ///
  Future<AssembledFile> _assembleFileBytes(
    final List<File> files, {
    bool forcePdf = false,
  }) async {
    assert(files.isNotEmpty);
    if (files.length == 1 && !forcePdf) {
      final ext = p.extension(files.first.path);
      return AssembledFile(ext, files.first.readAsBytesSync());
    }
    final doc = pw.Document();
    for (final file in files) {
      final img = pw.MemoryImage(file.readAsBytesSync());
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(
            img.width!.toDouble(),
            img.height!.toDouble(),
          ),
          build: (context) => pw.Image(img),
        ),
      );
    }
    return AssembledFile('.pdf', await doc.save());
  }
}

class AssembledFile {
  final String extension;
  final Uint8List bytes;

  AssembledFile(this.extension, this.bytes);
}
