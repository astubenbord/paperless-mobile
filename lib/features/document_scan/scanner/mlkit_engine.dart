import 'dart:io';

import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:paperless_mobile/core/service/file_service.dart';
import 'package:paperless_mobile/features/document_scan/scanner/document_scanner_engine.dart';

/// Scanner engine backed by Google ML Kit Document Scanner.
///
/// Opens Google's native camera UI with:
///  - automatic edge detection and perspective correction
///  - live auto-capture once the document is held steady
///  - multi-page support (the user can add further pages after each shot)
///
/// ML Kit processes images internally (brightness correction, perspective
/// correction, scan enhancement), so no additional post-processing is needed.
///
/// Requires Google Play Services on the device (ML Kit model).
class MlKitEngine implements DocumentScannerEngine {
  const MlKitEngine();

  @override
  Future<List<File>> scan() async {
    final options = DocumentScannerOptions(
      // JPEG for compatibility with the rest of the app (cubit, PDF assembly).
      documentFormats: {DocumentFormat.jpeg},
      // full = edge detection + auto-capture + image enhancement by ML Kit.
      mode: ScannerMode.full,
      // Generous limit; effectively constrained by the scanner UI in practice.
      pageLimit: 30,
      // Live camera only — no gallery import.
      isGalleryImport: false,
    );

    final scanner = DocumentScanner(options: options);
    try {
      final result = await scanner.scanDocument();

      final images = result.images;
      if (images == null || images.isEmpty) {
        // User cancelled without capturing a page.
        return [];
      }

      final List<File> outputFiles = [];
      for (final imagePath in images) {
        // ML Kit already delivers processed JPEGs; copy them into the app's
        // scan directory so FileService can manage their lifecycle (cleanup on
        // reset, etc.).
        final rawBytes = await File(imagePath).readAsBytes();
        final destFile = await FileService.instance.allocateTemporaryFile(
          PaperlessDirectoryType.scans,
          extension: 'jpeg',
          create: false,
        );
        await destFile.writeAsBytes(rawBytes, flush: true);
        outputFiles.add(destFile);
      }
      return outputFiles;
    } finally {
      // Release scanner resources on the Dart side.
      scanner.close();
    }
  }
}
