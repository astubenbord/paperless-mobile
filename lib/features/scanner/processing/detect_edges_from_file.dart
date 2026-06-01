import 'dart:typed_data';

import 'package:opencv_dart/opencv_dart.dart' as cv4;
import 'package:paperless_mobile/features/scanner/models/document_frame.dart';
import 'package:paperless_mobile/features/scanner/models/edge_detection_config.dart';
import 'package:paperless_mobile/features/scanner/processing/detect_edges.dart';

/// Detects document edges from a static image (PNG/JPEG bytes).
///
/// Uses [EdgeDetectionConfig.accurate] by default for higher-quality detection
/// on a captured still image. Pass a custom [config] to override.
///
/// Returns the detected [DocumentFrame] if a document quad is found, or `null`.
Future<DocumentFrame?> detectEdgesFromImageBytes(
  Uint8List imageBytes, {
  EdgeDetectionConfig config = EdgeDetectionConfig.accurate,
}) async {
  final mat = cv4.imdecode(imageBytes, cv4.IMREAD_COLOR);
  if (mat.isEmpty) return null;

  // Convert to RGBA (format expected by detectDocumentEdges).
  final rgba = await cv4.cvtColorAsync(mat, cv4.COLOR_BGR2RGBA);
  mat.dispose();

  final (frame, debugImage) = await detectDocumentEdges(rgba, config: config);
  debugImage?.dispose();
  rgba.dispose();

  return frame;
}
