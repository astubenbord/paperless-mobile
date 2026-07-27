import 'dart:developer' as dev;
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/api/paperless_api.dart';
import 'package:paperless_mobile/constants.dart';
import 'package:paperless_mobile/core/bloc/loading_status.dart';
import 'package:paperless_mobile/core/extensions/context_extensions.dart';
import 'package:paperless_mobile/core/global/constants.dart';
import 'package:paperless_mobile/core/model/info_message_exception.dart';
import 'package:paperless_mobile/core/service/file_service.dart';
import 'package:paperless_mobile/features/app_drawer/view/app_drawer.dart';
import 'package:paperless_mobile/features/document_scan/cubit/document_scanner_cubit.dart';
import 'package:paperless_mobile/features/document_scan/scanner/edge_detection_engine.dart';
import 'package:paperless_mobile/features/document_scan/scanner/mlkit_engine.dart';
import 'package:paperless_mobile/features/document_scan/view/widgets/export_scans_dialog.dart';
import 'package:paperless_mobile/features/document_scan/view/widgets/scanned_image_item.dart';
import 'package:paperless_mobile/features/document_search/view/sliver_search_bar.dart';
import 'package:paperless_mobile/features/document_upload/view/document_upload_preparation_page.dart';
import 'package:paperless_mobile/features/documents/view/pages/document_view.dart';
import 'package:paperless_mobile/features/settings/model/scanner_implementation.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/helpers/connectivity_aware_action_wrapper.dart';
import 'package:paperless_mobile/helpers/message_helpers.dart';
import 'package:paperless_mobile/helpers/permission_helpers.dart';
import 'package:paperless_mobile/routing/routes/scanner_route.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:sliver_tools/sliver_tools.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

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

  /// True while ML Kit capture and image processing is in progress.
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: true,
      child: Stack(
        children: [
          Scaffold(
            drawer: const AppDrawer(),
            floatingActionButton: FloatingActionButton.extended(
              heroTag: "fab_document_edit",
              onPressed:
                  _isProcessing ? null : () => _openDocumentScanner(context),
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add_a_photo_outlined),
              label: Text(
                _isProcessing
                    ? S.of(context)!.processingScan
                    : S.of(context)!.scanADocument,
              ),
            ),
            body: NestedScrollView(
              floatHeaderSlivers: true,
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverOverlapAbsorber(
                  handle: searchBarHandle,
                  sliver: SliverSearchBar(titleText: S.of(context)!.scanner),
                ),
                SliverOverlapAbsorber(
                  handle: actionsHandle,
                  sliver: SliverPinnedHeader(child: _buildActions()),
                ),
              ],
              body: BlocBuilder<DocumentScannerCubit, DocumentScannerState>(
                builder: (context, state) {
                  return switch (state.status) {
                    LoadingStatus.initial => _buildEmptyState(),
                    LoadingStatus.loading =>
                      Center(child: Text("Restoring...")),
                    LoadingStatus.loaded => _buildImageGrid(state.scans),
                    LoadingStatus.error => Placeholder(),
                  };
                },
              ),
            ),
          ),
          if (_isProcessing)
            Positioned.fill(
              child: ColoredBox(
                color: const Color(0x88000000),
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(S.of(context)!.processingScan),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
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
                                bytes: _assembleFileBytes(
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
                    onPressed: state.scans.isEmpty
                        ? null
                        : () => _reset(context),
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
    final globalSettings = context.localStore.state.globalSettings;
    final fileName = await showDialog<String>(
      useRootNavigator: false,
      context: context,
      builder: (context) => const ExportScansDialog(),
    );
    if (fileName != null) {
      if (!mounted) return;
      final cubit = context.read<DocumentScannerCubit>();
      final file = await _assembleFileBytes(
        forcePdf: true,
        context.read<DocumentScannerCubit>().state.scans,
      );
      try {
        if (Platform.isAndroid && androidInfo!.version.sdkInt <= 29) {
          final isGranted = await askForPermission(Permission.storage);
          if (!isGranted) {
            if (!mounted) return;
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
        if (!mounted) return;
        showGenericError(context, error);
      }
    }
  }

  void _openDocumentScanner(BuildContext context) async {
    final impl = context.localStore.state.globalSettings.preferredScanner;

    // ML Kit manages its own camera permission through Play Services;
    // edge_detection still requires an explicit permission request.
    if (impl == ScannerImplementation.edgeDetection) {
      final isGranted = await askForPermission(Permission.camera);
      if (!isGranted) return;
    }

    if (kDebugMode) {
      dev.log('[ScannerPage] Using scanner engine: $impl');
    }

    final engine = switch (impl) {
      ScannerImplementation.edgeDetection => const EdgeDetectionEngine(),
      ScannerImplementation.mlKit => const MlKitEngine(),
    };

    // Show a processing overlay while ML Kit capture + processing runs.
    if (impl == ScannerImplementation.mlKit && mounted) {
      setState(() => _isProcessing = true);
    }

    List<File> scannedFiles;
    try {
      scannedFiles = await engine.scan();
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }

    if (scannedFiles.isEmpty) {
      if (kDebugMode) {
        dev.log('[ScannerPage] Scan canceled or no images returned.');
      }
      return;
    }

    if (!context.mounted) return;

    if (impl == ScannerImplementation.mlKit) {
      // ML Kit flow: add pages to the cubit (grid as backup), then immediately
      // assemble a PDF and open the upload preparation page.
      final cubit = context.read<DocumentScannerCubit>();
      for (final file in scannedFiles) {
        cubit.addScan(file);
      }
      if (!context.mounted) return;
      await _onPrepareDocumentUploadMlKit(context, scannedFiles);
    } else {
      // edge_detection flow: add the single image to the grid; the user decides
      // when to upload.
      context.read<DocumentScannerCubit>().addScan(scannedFiles.first);
    }

    if (kDebugMode) {
      dev.log(
        '[ScannerPage] Added ${scannedFiles.length} scan(s) from $impl.',
      );
    }
  }

  /// ML Kit variant: always assembles a PDF (regardless of page count) and
  /// opens the upload preparation page directly.
  Future<void> _onPrepareDocumentUploadMlKit(
    BuildContext context,
    List<File> scans,
  ) async {
    final file = await _assembleFileBytes(scans, forcePdf: true);
    if (!context.mounted) return;
    final uploadResult = await DocumentUploadRoute(
      $extra: file.bytes,
      fileExtension: file.extension,
    ).push<DocumentUploadResult>(context);
    if (uploadResult?.success ?? false) {
      if (!context.mounted) return;
      context.read<DocumentScannerCubit>().reset();
    }
  }

  void _onPrepareDocumentUpload(BuildContext context, List<File> scans) async {
    final file = await _assembleFileBytes(
      scans,
      forcePdf:
          context.localStore.state.globalSettings.enforceSinglePagePdfUpload,
    );
    if (!context.mounted) return;
    final uploadResult = await DocumentUploadRoute(
      $extra: file.bytes,
      fileExtension: file.extension,
    ).push<DocumentUploadResult>(context);
    if (uploadResult?.success ?? false) {
      if (!context.mounted) return;
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
                onPressed: null,
                child: Text(S.of(context)!.uploadADocumentFromThisDevice),
              ),
              child: TextButton(
                onPressed: _onUploadFromFilesystem,
                child: Text(S.of(context)!.uploadADocumentFromThisDevice),
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
                    context.read<DocumentScannerCubit>().removeScan(
                      scans[index],
                    );
                  } on PaperlessApiException catch (error, stackTrace) {
                    showErrorMessage(context, error, stackTrace);
                  } on InfoMessageException catch (error, stackTrace) {
                    showInfoMessage(context, error, stackTrace);
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
      allowedExtensions: supportedFileExtensions
          .map((e) => e.replaceAll(".", ""))
          .toList(),
      withData: true,
      allowMultiple: false,
    );
    if (result?.files.single.path != null) {
      final path = result!.files.single.path!;
      final extension = p.extension(path);
      final filename = p.basenameWithoutExtension(path);
      File file = File(path);
      if (!supportedFileExtensions.contains(extension.toLowerCase())) {
        if (!mounted) return;
        showErrorMessage(
          context,
          const PaperlessApiException(ErrorCode.unsupportedFileFormat),
        );
        return;
      }
      if (!mounted) return;
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
