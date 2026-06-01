import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:opencv_dart/opencv_dart.dart' as cv4;
import 'package:paperless_mobile/features/scanner/models/document_frame.dart';

/// Applies a perspective (four-point) transform to [imageBytes] so that the
/// quadrilateral defined by [frame] is warped into an axis-aligned rectangle.
///
/// Returns the transformed image as PNG-encoded bytes.
Future<Uint8List> perspectiveTransform({
  required Uint8List imageBytes,
  required DocumentFrame frame,
}) async {
  // Decode the image using OpenCV.
  final mat = cv4.imdecode(imageBytes, cv4.IMREAD_COLOR);

  final srcPoints = [
    cv4.Point2f(frame.topLeft.dx.toDouble(), frame.topLeft.dy.toDouble()),
    cv4.Point2f(frame.topRight.dx.toDouble(), frame.topRight.dy.toDouble()),
    cv4.Point2f(
      frame.bottomRight.dx.toDouble(),
      frame.bottomRight.dy.toDouble(),
    ),
    cv4.Point2f(frame.bottomLeft.dx.toDouble(), frame.bottomLeft.dy.toDouble()),
  ];

  // Compute the output dimensions from the maximum width/height of the quad.
  final widthTop = _distance(frame.topLeft, frame.topRight);
  final widthBottom = _distance(frame.bottomLeft, frame.bottomRight);
  final maxWidth = math.max(widthTop, widthBottom).roundToDouble();

  final heightLeft = _distance(frame.topLeft, frame.bottomLeft);
  final heightRight = _distance(frame.topRight, frame.bottomRight);
  final maxHeight = math.max(heightLeft, heightRight).roundToDouble();

  final dstPoints = [
    cv4.Point2f(0, 0),
    cv4.Point2f(maxWidth - 1, 0),
    cv4.Point2f(maxWidth - 1, maxHeight - 1),
    cv4.Point2f(0, maxHeight - 1),
  ];

  final srcMat = cv4.VecPoint2f.fromList(srcPoints);
  final dstMat = cv4.VecPoint2f.fromList(dstPoints);

  final transform = cv4.getPerspectiveTransform2f(srcMat, dstMat);

  final warped = await cv4.warpPerspectiveAsync(mat, transform, (
    maxWidth.toInt(),
    maxHeight.toInt(),
  ));

  final (success, encoded) = cv4.imencode('.png', warped);
  mat.dispose();
  warped.dispose();
  transform.dispose();

  if (!success) {
    throw Exception('Failed to encode perspective-transformed image');
  }

  return encoded;
}

double _distance(Offset a, Offset b) {
  final dx = a.dx - b.dx;
  final dy = a.dy - b.dy;
  return math.sqrt(dx * dx + dy * dy);
}
