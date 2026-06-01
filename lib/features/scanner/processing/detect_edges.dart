import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv4;
import 'package:paperless_mobile/features/scanner/models/debug_stage.dart';
import 'package:paperless_mobile/features/scanner/models/document_frame.dart';
import 'package:paperless_mobile/features/scanner/models/edge_detection_config.dart';
import 'package:paperless_mobile/features/scanner/models/input_image.dart';
import 'package:paperless_mobile/features/scanner/utils/utils.dart';

final _orientations = {
  DeviceOrientation.portraitUp: 0,
  DeviceOrientation.landscapeLeft: 90,
  DeviceOrientation.portraitDown: 180,
  DeviceOrientation.landscapeRight: 270,
};

/// Computes the rotation compensation needed based on device and sensor
/// orientation. Returns null if inputs are insufficient.
int? computeRotationCompensation(
  int? sensorOrientation,
  DeviceOrientation deviceOrientation,
  CameraLensDirection lensDirection,
) {
  var rotationCompensation = _orientations[deviceOrientation];
  if (rotationCompensation == null || sensorOrientation == null) return null;
  if (lensDirection == CameraLensDirection.front) {
    rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
  } else {
    rotationCompensation =
        (sensorOrientation - rotationCompensation + 360) % 360;
  }
  return rotationCompensation;
}

/// Extracts RGBA bytes and rotation compensation from a [CameraImage].
/// Returns null if the format is unsupported or rotation cannot be computed.
({Uint8List bytes, int width, int height, int rotation})? prepareCameraImage(
  CameraImage image,
  int? sensorOrientation,
  DeviceOrientation deviceOrientation,
  CameraLensDirection lensDirection,
) {
  final format = InputImageFormatValue.fromRawValue(image.format.raw);
  if (format == null) return null;

  final bytes = switch (format) {
    InputImageFormat.yuv_420_888 => yuv420ToRGBA8888(image),
    InputImageFormat.nv21 => nv21ToRGBA8888(image),
    InputImageFormat.bgra8888 => bgraToRgbaInPlace(image.planes.first.bytes),
    _ => throw UnimplementedError(),
  };

  final rotation = computeRotationCompensation(
    sensorOrientation,
    deviceOrientation,
    lensDirection,
  );
  if (rotation == null) return null;

  return (
    bytes: bytes,
    width: image.width,
    height: image.height,
    rotation: rotation,
  );
}

void processImage(
  CameraImage image,
  int? sensorOrientation,
  DeviceOrientation deviceOrientation,
  CameraLensDirection lensDirection,
  void Function(DocumentFrame frame, Size imageSize, ui.Image? debugImage)
  onFrameDetected, {
  DebugStage debugStage = DebugStage.none,
}) async {
  final format = InputImageFormatValue.fromRawValue(image.format.raw);
  if (format == null) return;

  final bytes = switch (format) {
    InputImageFormat.yuv_420_888 => yuv420ToRGBA8888(image),
    InputImageFormat.nv21 => nv21ToRGBA8888(image),
    InputImageFormat.bgra8888 => bgraToRgbaInPlace(image.planes.first.bytes),
    _ => throw UnimplementedError(),
  };

  cv4.Mat mat = cv4.Mat.fromList(
    image.height,
    image.width,
    cv4.MatType.CV_8UC4,
    bytes,
  );

  final rotationCompensation = computeRotationCompensation(
    sensorOrientation,
    deviceOrientation,
    lensDirection,
  );
  if (rotationCompensation == null) return;

  switch (rotationCompensation) {
    case 90:
      await cv4.rotateAsync(mat, cv4.ROTATE_90_CLOCKWISE, dst: mat);
      break;
    case 180:
      await cv4.rotateAsync(mat, cv4.ROTATE_180, dst: mat);
      break;
    case 270:
      await cv4.rotateAsync(mat, cv4.ROTATE_90_COUNTERCLOCKWISE, dst: mat);
      break;
    default:
      // no rotation needed
      break;
  }

  final (frame, debugImage) = await detectDocumentEdges(
    mat,
    debugStage: debugStage,
  );
  final imageSize = Size(mat.cols.toDouble(), mat.rows.toDouble());
  mat.dispose();
  if (frame != null) {
    onFrameDetected(frame, imageSize, debugImage);
  }
}

// Fixed algorithm constants (not configurable per-preset):

/// Maximum cosine of interior angles for a valid quadrilateral. Angles close to
/// 90° have cosine close to 0; 0.4 allows moderate perspective.
const _expectedMaxCosine = 0.4;

/// If a quad's maxCosine is below this AND its area exceeds
/// [_expectedAreaFactor] of the image, we stop searching early.
const _expectedOptimalMaxCosine = 0.3;

/// Area fraction for the "optimal early-exit" heuristic.
const _expectedAreaFactor = 0.20;

/// Binary threshold value used in the threshold-based detection pass.
const _threshValue = 160.0;
const _threshMax = 256.0;

/// Canny factor: for a base value `t`, low threshold = `t * cannyFactor`,
/// high threshold = `t * cannyFactor * 2`.
const _cannyFactor = 2.0;

/// A candidate quad: (points, area, maxCosine, meanCosine, weight).
typedef _QuadCandidate = (List<cv4.Point>, double, double, double, double);

Future<(DocumentFrame?, ui.Image?)> detectDocumentEdges(
  cv4.Mat mat, {
  EdgeDetectionConfig config = EdgeDetectionConfig.fast,
  DebugStage debugStage = DebugStage.none,
}) async {
  // 1. Convert RGBA → grayscale for single-channel processing.
  final gray = await cv4.cvtColorAsync(mat, cv4.COLOR_RGBA2GRAY);

  // 2. Resize to processing resolution for speed.
  final originalWidth = gray.cols.toDouble();
  final originalHeight = gray.rows.toDouble();
  final maxDim = math.max(originalWidth, originalHeight);
  final double resizeScaleX;
  final double resizeScaleY;
  cv4.Mat resized;
  if (config.resizeThreshold > 0 && maxDim > config.resizeThreshold) {
    final approxScale = maxDim / config.resizeThreshold;
    final newW = math.max(1, (originalWidth / approxScale).round());
    final newH = math.max(1, (originalHeight / approxScale).round());
    resizeScaleX = originalWidth / newW;
    resizeScaleY = originalHeight / newH;
    resized = await cv4.resizeAsync(gray, (newW, newH));
  } else {
    resizeScaleX = 1.0;
    resizeScaleY = 1.0;
    resized = gray.clone();
  }
  gray.dispose();

  // 3. Add border padding so documents at frame edges are found.
  final bordered = await cv4.copyMakeBorderAsync(
    resized,
    config.borderSize,
    config.borderSize,
    config.borderSize,
    config.borderSize,
    cv4.BORDER_CONSTANT,
    value: cv4.Scalar.black,
  );
  resized.dispose();

  final width = bordered.cols.toDouble();
  final height = bordered.rows.toDouble();

  // 4. Median blur to reduce noise while preserving edges.
  final blurred = await cv4.medianBlurAsync(bordered, config.medianBlurKernel);

  // Debug: grayscale stage shows the first channel after blur.
  if (debugStage == DebugStage.grayscale) {
    final dbg = await _grayMatToUiImage(blurred);
    final result = await _scanPoint(
      blurred,
      bordered,
      width,
      height,
      resizeScaleX,
      resizeScaleY,
      config,
    );
    blurred.dispose();
    bordered.dispose();
    return (result, dbg);
  }

  if (debugStage == DebugStage.blurred) {
    final dbg = await _grayMatToUiImage(blurred);
    final result = await _scanPoint(
      blurred,
      bordered,
      width,
      height,
      resizeScaleX,
      resizeScaleY,
      config,
    );
    blurred.dispose();
    bordered.dispose();
    return (result, dbg);
  }

  // Debug stages for intermediate processing.
  if (debugStage == DebugStage.canny || debugStage == DebugStage.morphClosed) {
    final (_, edged) = await cv4.thresholdAsync(
      blurred,
      _threshValue,
      _threshMax,
      cv4.THRESH_BINARY,
    );
    final morphKernel = cv4.getStructuringElement(cv4.MORPH_RECT, (
      config.morphologyKernel,
      config.morphologyKernel,
    ));
    final dilateKernel = cv4.getStructuringElement(cv4.MORPH_RECT, (
      config.dilateKernel,
      config.dilateKernel,
    ));
    final closed = await cv4.morphologyExAsync(
      edged,
      cv4.MORPH_CLOSE,
      morphKernel,
    );
    final dilated = await cv4.dilateAsync(closed, dilateKernel);
    final dbg = await _grayMatToUiImage(
      debugStage == DebugStage.canny ? edged : dilated,
    );
    edged.dispose();
    closed.dispose();
    dilated.dispose();
    morphKernel.dispose();
    dilateKernel.dispose();
    final result = await _scanPoint(
      blurred,
      bordered,
      width,
      height,
      resizeScaleX,
      resizeScaleY,
      config,
    );
    blurred.dispose();
    bordered.dispose();
    return (result, dbg);
  }

  if (debugStage == DebugStage.contours) {
    final (result, dbg) = await _scanPointWithDebug(
      blurred,
      bordered,
      width,
      height,
      resizeScaleX,
      resizeScaleY,
      config,
    );
    blurred.dispose();
    bordered.dispose();
    return (result, dbg);
  }

  final result = await _scanPoint(
    blurred,
    bordered,
    width,
    height,
    resizeScaleX,
    resizeScaleY,
    config,
  );
  blurred.dispose();
  bordered.dispose();
  return (result, null);
}

/// Core detection pipeline adapted from OSS-DocumentScanner.
///
/// On the single grayscale channel:
///   1. Binary threshold → morphological close → dilate → find quads
///   2. Canny passes at t=50,30,10 → dilate → find quads
///
/// Threshold-based contours get higher weight than Canny-based ones.
/// The best candidate is chosen by a score combining area, weight, and angle.
Future<DocumentFrame?> _scanPoint(
  cv4.Mat blurred,
  cv4.Mat image,
  double width,
  double height,
  double resizeScaleX,
  double resizeScaleY,
  EdgeDetectionConfig config,
) async {
  final candidates = await _collectCandidates(blurred, width, height, config);
  if (candidates.isEmpty) return null;

  // Sort by score: area + weight * (1 - maxCosine).
  candidates.sort((a, b) {
    final scoreA = a.$2 + a.$5 * (1 - a.$3);
    final scoreB = b.$2 + b.$5 * (1 - b.$3);
    return scoreB.compareTo(scoreA);
  });

  final best = candidates.first;
  final points = best.$1;

  // Remove border offset and scale back to original coordinates.
  final scaled = points.map((p) {
    final x = (p.x - config.borderSize) * resizeScaleX;
    final y = (p.y - config.borderSize) * resizeScaleY;
    return Offset(math.max(0, x), math.max(0, y));
  }).toList();

  return _orderCornerOffsets(scaled);
}

/// Collects all valid quad candidates from the single grayscale channel.
Future<List<_QuadCandidate>> _collectCandidates(
  cv4.Mat blurred,
  double width,
  double height,
  EdgeDetectionConfig config,
) async {
  final morphKernel = cv4.getStructuringElement(cv4.MORPH_RECT, (
    config.morphologyKernel,
    config.morphologyKernel,
  ));
  final dilateKernel = cv4.getStructuringElement(cv4.MORPH_RECT, (
    config.dilateKernel,
    config.dilateKernel,
  ));

  final List<_QuadCandidate> allCandidates = [];
  var weight = 3000000.0;
  final maxAllowedArea =
      (width - 2 * config.borderSize) * (height - 2 * config.borderSize) * 0.92;

  try {
    // --- Pass 1: Binary threshold ---
    final (_, threshed) = await cv4.thresholdAsync(
      blurred,
      _threshValue,
      _threshMax,
      cv4.THRESH_BINARY,
    );
    final closed1 = await cv4.morphologyExAsync(
      threshed,
      cv4.MORPH_CLOSE,
      morphKernel,
    );
    threshed.dispose();
    final dilated1 = await cv4.dilateAsync(closed1, dilateKernel);
    closed1.dispose();

    _findSquares(
      dilated1,
      width,
      height,
      maxAllowedArea,
      allCandidates,
      weight,
      config,
    );
    dilated1.dispose();
    weight -= 1;

    // --- Pass 2: Canny with fewer threshold steps ---
    if (!_hasOptimalCandidate(allCandidates, width, height)) {
      for (final t in [50, 30, 10]) {
        final lowThreshold = t * _cannyFactor;
        final highThreshold = lowThreshold * 2;
        final edges = await cv4.cannyAsync(
          blurred,
          lowThreshold,
          highThreshold,
        );
        final dilatedEdge = await cv4.dilateAsync(edges, dilateKernel);
        edges.dispose();

        _findSquares(
          dilatedEdge,
          width,
          height,
          maxAllowedArea,
          allCandidates,
          weight,
          config,
        );
        dilatedEdge.dispose();
        weight -= 1;

        if (_hasOptimalCandidate(allCandidates, width, height)) break;
      }
    }
  } finally {
    morphKernel.dispose();
    dilateKernel.dispose();
  }

  return allCandidates;
}

/// Checks if the best candidate so far is already optimal (good angles and
/// large enough area) to allow early termination.
bool _hasOptimalCandidate(
  List<_QuadCandidate> candidates,
  double width,
  double height,
) {
  if (candidates.isEmpty) return false;
  // Sort to find best.
  candidates.sort((a, b) {
    final scoreA = a.$2 + a.$5 * (1 - a.$3);
    final scoreB = b.$2 + b.$5 * (1 - b.$3);
    return scoreB.compareTo(scoreA);
  });
  final best = candidates.first;
  return best.$3 < _expectedOptimalMaxCosine &&
      best.$2 > (width * height * _expectedAreaFactor);
}

/// Finds quadrilateral contours in a binary image and appends valid candidates.
void _findSquares(
  cv4.Mat binaryImage,
  double scaledWidth,
  double scaledHeight,
  double maxAllowedArea,
  List<_QuadCandidate> squares,
  double weight,
  EdgeDetectionConfig config,
) {
  final (contours, hierarchy) = cv4.findContours(
    binaryImage,
    cv4.RETR_TREE,
    cv4.CHAIN_APPROX_SIMPLE,
  );
  hierarchy.dispose();

  for (final contour in contours) {
    final arcLen = cv4.arcLength(contour, true);
    final area = cv4.contourArea(contour);
    if (arcLen < 100 ||
        area < (scaledWidth * scaledHeight) * config.minAreaFactor ||
        area >= maxAllowedArea) {
      continue;
    }

    final epsilon = arcLen * config.approxEpsilonFactor;
    final approx = cv4.approxPolyDP(contour, epsilon, true);
    if (approx.length != 4 || !cv4.isContourConvex(approx)) {
      approx.dispose();
      continue;
    }

    // Check that no corner is too close to the border.
    final marge = (scaledWidth * 0.0).toInt() + config.borderSize;
    var shouldIgnore = false;
    for (var j = 0; j < 4; j++) {
      final p = approx[j];
      if (p.x < marge ||
          p.x >= scaledWidth - marge ||
          p.y < marge ||
          p.y >= scaledHeight - marge) {
        shouldIgnore = true;
        break;
      }
    }
    if (shouldIgnore) {
      approx.dispose();
      continue;
    }

    // Validate interior angles via cosine check.
    var maxCosine = 0.0;
    var meanCosine = 0.0;
    for (var j = 2; j < 6; j++) {
      final cosine = _angleCosine(
        approx[j % 4],
        approx[j - 2],
        approx[(j - 1) % 4],
      ).abs();
      maxCosine = math.max(maxCosine, cosine);
      meanCosine += cosine;
    }
    meanCosine /= 4.0;

    if (maxCosine < _expectedMaxCosine) {
      final points = List.generate(
        4,
        (i) => cv4.Point(approx[i].x, approx[i].y),
      );
      squares.add((points, area, maxCosine, meanCosine, weight));
    }
    approx.dispose();
  }
  contours.dispose();
}

/// Cosine of the angle at vertex pt0 formed by pt1-pt0-pt2.
double _angleCosine(cv4.Point pt1, cv4.Point pt2, cv4.Point pt0) {
  final dx1 = (pt1.x - pt0.x).toDouble();
  final dy1 = (pt1.y - pt0.y).toDouble();
  final dx2 = (pt2.x - pt0.x).toDouble();
  final dy2 = (pt2.y - pt0.y).toDouble();
  return (dx1 * dx2 + dy1 * dy2) /
      math.sqrt((dx1 * dx1 + dy1 * dy1) * (dx2 * dx2 + dy2 * dy2) + 1e-10);
}

/// Orders four [Offset] points into top-left, top-right, bottom-right,
/// bottom-left by their spatial position.
DocumentFrame _orderCornerOffsets(List<Offset> points) {
  // Sort by Y first, then within top/bottom pairs by X.
  points.sort((a, b) => a.dy.compareTo(b.dy));
  // Top two points.
  final top = points.sublist(0, 2)..sort((a, b) => a.dx.compareTo(b.dx));
  // Bottom two points, sorted X descending for winding order.
  final bottom = points.sublist(2, 4)..sort((a, b) => b.dx.compareTo(a.dx));

  return DocumentFrame(
    topLeft: top[0],
    topRight: top[1],
    bottomRight: bottom[0],
    bottomLeft: bottom[1],
  );
}

// ---------------------------------------------------------------------------
// Debug helpers
// ---------------------------------------------------------------------------

/// Converts a single-channel (grayscale) Mat into a [ui.Image] for display.
/// Uses OpenCV's native color conversion instead of a Dart pixel loop.
Future<ui.Image> _grayMatToUiImage(cv4.Mat gray) async {
  final rgba = await cv4.cvtColorAsync(gray, cv4.COLOR_GRAY2RGBA);
  final image = await rgba.toUiImage();
  rgba.dispose();
  return image;
}

/// Like [_scanPoint] but also returns a debug image with contours drawn.
Future<(DocumentFrame?, ui.Image?)> _scanPointWithDebug(
  cv4.Mat blurred,
  cv4.Mat image,
  double width,
  double height,
  double resizeScaleX,
  double resizeScaleY,
  EdgeDetectionConfig config,
) async {
  final canvas = cv4.Mat.zeros(image.rows, image.cols, cv4.MatType.CV_8UC4);

  final candidates = await _collectCandidates(blurred, width, height, config);

  if (candidates.isEmpty) {
    final dbg = await canvas.toUiImage();
    canvas.dispose();
    return (null, dbg);
  }

  // Draw all candidates in green.
  for (final c in candidates) {
    final pts = cv4.VecVecPoint.fromList([c.$1]);
    await cv4.drawContoursAsync(
      canvas,
      pts,
      0,
      cv4.Scalar(0, 255, 0, 255),
      thickness: 1,
    );
    pts.dispose();
  }

  // Sort and pick best.
  candidates.sort((a, b) {
    final scoreA = a.$2 + a.$5 * (1 - a.$3);
    final scoreB = b.$2 + b.$5 * (1 - b.$3);
    return scoreB.compareTo(scoreA);
  });
  final best = candidates.first;

  // Draw best in red.
  final bestPts = cv4.VecVecPoint.fromList([best.$1]);
  await cv4.drawContoursAsync(
    canvas,
    bestPts,
    0,
    cv4.Scalar(255, 0, 0, 255),
    thickness: 3,
  );
  bestPts.dispose();

  final dbg = await canvas.toUiImage();
  canvas.dispose();

  final points = best.$1;
  final scaled = points.map((p) {
    final x = (p.x - config.borderSize) * resizeScaleX;
    final y = (p.y - config.borderSize) * resizeScaleY;
    return Offset(math.max(0, x), math.max(0, y));
  }).toList();

  return (_orderCornerOffsets(scaled), dbg);
}
