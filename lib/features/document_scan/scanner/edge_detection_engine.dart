import 'dart:io';

import 'package:edge_detection/edge_detection.dart';
import 'package:paperless_mobile/core/service/file_service.dart';
import 'package:paperless_mobile/features/document_scan/scanner/document_scanner_engine.dart';

/// Scanner engine backed by the [edge_detection] package.
///
/// Opens the native camera UI with automatic edge detection and returns a
/// single JPEG file. Returns an empty list when the user cancels or the scan
/// fails.
class EdgeDetectionEngine implements DocumentScannerEngine {
  const EdgeDetectionEngine();

  @override
  Future<List<File>> scan() async {
    final file = await FileService.instance.allocateTemporaryFile(
      PaperlessDirectoryType.scans,
      extension: 'jpeg',
      create: true,
    );

    final success = await EdgeDetection.detectEdge(file.path);
    if (!success) {
      return [];
    }
    return [file];
  }
}
