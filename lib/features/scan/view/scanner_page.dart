import 'dart:developer' as dev;
import 'dart:io';
import 'dart:math';

import 'package:edge_detection/edge_detection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mime/mime.dart';
import 'package:paperless_mobile/core/bloc/label_bloc_provider.dart';
import 'package:paperless_mobile/core/global/constants.dart';
import 'package:paperless_mobile/core/model/error_message.dart';
import 'package:paperless_mobile/core/service/file_service.dart';
import 'package:paperless_mobile/di_initializer.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/documents/repository/document_repository.dart';
import 'package:paperless_mobile/features/documents/view/pages/document_view.dart';
import 'package:paperless_mobile/features/home/view/widget/info_drawer.dart';
import 'package:paperless_mobile/features/scan/bloc/document_scanner_cubit.dart';
import 'package:paperless_mobile/features/scan/view/document_upload_page.dart';
import 'package:paperless_mobile/features/scan/view/widgets/grid_image_item_widget.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:paperless_mobile/util.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({Key? key}) : super(key: key);

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const InfoDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openDocumentScanner(context),
        child: const Icon(Icons.add_a_photo_outlined),
      ),
      appBar: _buildAppBar(context),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _buildBody(),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(S.of(context).documentScannerPageTitle),
      actions: [
        BlocBuilder<DocumentScannerCubit, List<File>>(
          builder: (context, state) {
            return IconButton(
              onPressed: state.isNotEmpty
                  ? () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => DocumentView(
                            documentBytes:
                                _buildDocumentFromImageFiles(state).save(),
                          ),
                        ),
                      )
                  : null,
              icon: const Icon(Icons.preview),
              tooltip: S.of(context).documentScannerPageResetButtonTooltipText,
            );
          },
        ),
        BlocBuilder<DocumentScannerCubit, List<File>>(
          builder: (context, state) {
            return IconButton(
              onPressed: state.isEmpty ? null : () => _reset(context),
              icon: const Icon(Icons.delete_sweep),
              tooltip: S.of(context).documentScannerPageResetButtonTooltipText,
            );
          },
        ),
        BlocBuilder<DocumentScannerCubit, List<File>>(
          builder: (context, state) {
            return IconButton(
              onPressed: state.isEmpty
                  ? null
                  : () => _onPrepareDocumentUpload(context),
              icon: const Icon(Icons.done),
              tooltip: S.of(context).documentScannerPageUploadButtonTooltip,
            );
          },
        ),
      ],
    );
  }

  void _openDocumentScanner(BuildContext context) async {
    await _requestCameraPermissions();
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
    BlocProvider.of<DocumentScannerCubit>(context).addScan(file);
  }

  void _onPrepareDocumentUpload(BuildContext context) async {
    final doc = _buildDocumentFromImageFiles(
      BlocProvider.of<DocumentScannerCubit>(context).state,
    );
    final bytes = await doc.save();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: getIt<DocumentsCubit>(),
          child: LabelBlocProvider(
            child: DocumentUploadPage(
              fileBytes: bytes,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<DocumentScannerCubit, List<File>>(
      builder: (context, scans) {
        if (scans.isNotEmpty) {
          return _buildImageGrid(scans);
        }
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  S.of(context).documentScannerPageEmptyStateText,
                  textAlign: TextAlign.center,
                ),
                TextButton(
                  child:
                      Text(S.of(context).documentScannerPageAddScanButtonLabel),
                  onPressed: () => _openDocumentScanner(context),
                ),
                Text(S.of(context).documentScannerPageOrText),
                TextButton(
                  child: Text(S
                      .of(context)
                      .documentScannerPageUploadFromThisDeviceButtonLabel),
                  onPressed: _onUploadFromFilesystem,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageGrid(List<File> scans) {
    return GridView.builder(
        itemCount: scans.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1 / sqrt(2),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemBuilder: (context, index) {
          return GridImageItemWidget(
            file: scans[index],
            onDelete: () async {
              try {
                BlocProvider.of<DocumentScannerCubit>(context)
                    .removeScan(index);
              } on ErrorMessage catch (error, stackTrace) {
                showErrorMessage(context, error, stackTrace);
              }
            },
            index: index,
            totalNumberOfFiles: scans.length,
          );
        });
  }

  void _reset(BuildContext context) {
    try {
      BlocProvider.of<DocumentScannerCubit>(context).reset();
    } on ErrorMessage catch (error, stackTrace) {
      showErrorMessage(context, error, stackTrace);
    }
  }

  Future<void> _requestCameraPermissions() async {
    final hasPermission = await Permission.camera.isGranted;
    if (!hasPermission) {
      await Permission.camera.request();
    }
  }

  void _onUploadFromFilesystem() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: supportedFileExtensions,
      withData: true,
    );
    if (result?.files.single.path != null) {
      File file = File(result!.files.single.path!);
      if (!supportedFileExtensions.contains(
        file.path.split('.').last.toLowerCase(),
      )) {
        showErrorMessage(
          context,
          const ErrorMessage(ErrorCode.unsupportedFileFormat),
        );
        return;
      }
      final filename = extractFilenameFromPath(file.path);
      final mimeType = lookupMimeType(file.path) ?? '';
      late Uint8List fileBytes;
      if (mimeType.startsWith('image')) {
        fileBytes = await _buildDocumentFromImageFiles([file]).save();
      } else {
        // pdf
        fileBytes = file.readAsBytesSync();
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BlocProvider.value(
            value: getIt<DocumentsCubit>(),
            child: LabelBlocProvider(
              child: DocumentUploadPage(
                filename: filename,
                fileBytes: fileBytes,
              ),
            ),
          ),
        ),
      );
    }
  }

  pw.Document _buildDocumentFromImageFiles(List<File> files) {
    final doc = pw.Document();
    for (final file in files) {
      final img = pw.MemoryImage(file.readAsBytesSync());
      doc.addPage(
        pw.Page(
          pageFormat:
              PdfPageFormat(img.width!.toDouble(), img.height!.toDouble()),
          build: (context) => pw.Image(img),
        ),
      );
    }
    return doc;
  }
}
