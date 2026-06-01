import 'dart:io';
import 'dart:ui';

import 'package:paperless_mobile/features/scanner/models/document_frame.dart';
import 'package:path/path.dart' as p;

/// Color filter options for scanned images.
enum ScanColorFilter { none, greyscale, blackAndWhite }

/// Stores a scanned document with its persisted transformation parameters.
class ScanResult {
  /// The original captured image file name (full resolution, no crop).
  final String originalFileName;

  /// The edited image file name.
  final String editedFileName;

  /// Pixel dimensions of the original image.
  final Size originalImageSize;

  /// The crop frame applied to the original image.
  final DocumentFrame cropFrame;

  /// How many 90° clockwise turns have been applied (0–3).
  final int quarterTurns;

  /// The color filter applied.
  final ScanColorFilter colorFilter;

  /// B&W adaptive threshold constant (only relevant when [colorFilter] is
  /// [ScanColorFilter.blackAndWhite]).
  final double bwThreshold;

  /// Whether auto-enhance was applied.
  final bool enhanced;

  const ScanResult({
    required this.originalFileName,
    required this.editedFileName,
    required this.originalImageSize,
    required this.cropFrame,
    required this.quarterTurns,
    required this.colorFilter,
    required this.bwThreshold,
    required this.enhanced,
  });

  double get originalImageWidth => originalImageSize.width;

  double get originalImageHeight => originalImageSize.height;

  ScanResult copyWith({
    String? originalFileName,
    String? editedFileName,
    Size? originalImageSize,
    DocumentFrame? cropFrame,
    int? quarterTurns,
    ScanColorFilter? colorFilter,
    double? bwThreshold,
    bool? enhanced,
  }) {
    return ScanResult(
      originalFileName: originalFileName ?? this.originalFileName,
      editedFileName: editedFileName ?? this.editedFileName,
      originalImageSize: originalImageSize ?? this.originalImageSize,
      cropFrame: cropFrame ?? this.cropFrame,
      quarterTurns: quarterTurns ?? this.quarterTurns,
      colorFilter: colorFilter ?? this.colorFilter,
      bwThreshold: bwThreshold ?? this.bwThreshold,
      enhanced: enhanced ?? this.enhanced,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'originalFileName': originalFileName,
      'editedFileName': editedFileName,
      'originalImageWidth': originalImageWidth,
      'originalImageHeight': originalImageHeight,
      'cropFrame': _frameToJson(cropFrame),
      'quarterTurns': quarterTurns,
      'colorFilter': colorFilter.name,
      'bwThreshold': bwThreshold,
      'enhanced': enhanced,
    };
  }

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      originalFileName: p.basename(
        (json['originalFilePath'] as String?) ??
            (json['originalFileName'] as String),
      ),
      editedFileName: p.basename(
        (json['editedFilePath'] as String?) ??
            (json['editedFileName'] as String),
      ),
      originalImageSize: Size(
        (json['originalImageWidth'] as num?)?.toDouble() ?? 0,
        (json['originalImageHeight'] as num?)?.toDouble() ?? 0,
      ),
      cropFrame: _frameFromJson(json['cropFrame'] as Map<String, dynamic>),
      quarterTurns: json['quarterTurns'] as int? ?? 0,
      colorFilter: _scanColorFilterFromName(
        json['colorFilter'] as String? ?? ScanColorFilter.none.name,
      ),
      bwThreshold: (json['bwThreshold'] as num?)?.toDouble() ?? 10,
      enhanced: json['enhanced'] as bool? ?? false,
    );
  }

  File originalFile(Directory originalDirectory) {
    return File(p.join(originalDirectory.path, originalFileName));
  }

  File editedFile(Directory editedDirectory) {
    return File(p.join(editedDirectory.path, editedFileName));
  }
}

Map<String, dynamic> _frameToJson(DocumentFrame frame) {
  return {
    'topLeft': _offsetToJson(frame.topLeft),
    'topRight': _offsetToJson(frame.topRight),
    'bottomRight': _offsetToJson(frame.bottomRight),
    'bottomLeft': _offsetToJson(frame.bottomLeft),
  };
}

DocumentFrame _frameFromJson(Map<String, dynamic> json) {
  return DocumentFrame(
    topLeft: _offsetFromJson(json['topLeft'] as Map<String, dynamic>),
    topRight: _offsetFromJson(json['topRight'] as Map<String, dynamic>),
    bottomRight: _offsetFromJson(json['bottomRight'] as Map<String, dynamic>),
    bottomLeft: _offsetFromJson(json['bottomLeft'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _offsetToJson(Offset offset) {
  return {'dx': offset.dx, 'dy': offset.dy};
}

Offset _offsetFromJson(Map<String, dynamic> json) {
  return Offset((json['dx'] as num).toDouble(), (json['dy'] as num).toDouble());
}

ScanColorFilter _scanColorFilterFromName(String name) {
  return ScanColorFilter.values.firstWhere(
    (value) => value.name == name,
    orElse: () => ScanColorFilter.none,
  );
}
