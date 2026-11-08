import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:paperless_mobile/features/scanner/models/document_frame.dart';
import 'package:paperless_mobile/features/scanner/models/scan_result.dart';

class TransientScanResult {
  final File originalFile;
  final File outputFile;
  Uint8List thumbnailBytes;
  ScanResult _scanResult;

  TransientScanResult({
    required this.originalFile,
    required this.outputFile,
    required this.thumbnailBytes,
    required ScanResult scanResult,
  }) : _scanResult = scanResult;

  ScanResult get scanResult => _scanResult;

  Size get originalImageSize => _scanResult.originalImageSize;

  DocumentFrame get cropFrame => _scanResult.cropFrame;

  set cropFrame(DocumentFrame value) {
    _scanResult = _scanResult.copyWith(cropFrame: value);
  }

  int get quarterTurns => _scanResult.quarterTurns;

  set quarterTurns(int value) {
    _scanResult = _scanResult.copyWith(quarterTurns: value);
  }

  ScanColorFilter get colorFilter => _scanResult.colorFilter;

  set colorFilter(ScanColorFilter value) {
    _scanResult = _scanResult.copyWith(colorFilter: value);
  }

  double get bwThreshold => _scanResult.bwThreshold;

  set bwThreshold(double value) {
    _scanResult = _scanResult.copyWith(bwThreshold: value);
  }

  bool get enhanced => _scanResult.enhanced;

  set enhanced(bool value) {
    _scanResult = _scanResult.copyWith(enhanced: value);
  }
}
