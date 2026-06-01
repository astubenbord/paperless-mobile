import 'dart:typed_data';

import 'package:opencv_dart/opencv_dart.dart' as cv4;

/// Rotates [imageBytes] (PNG) by [quarterTurns] × 90° clockwise.
///
/// [quarterTurns] is normalised to 0–3. Returns the original bytes unchanged
/// when the effective rotation is 0°.
Future<Uint8List> rotateImage(Uint8List imageBytes, int quarterTurns) async {
  final effective = quarterTurns % 4;
  if (effective == 0) return imageBytes;

  final mat = cv4.imdecode(imageBytes, cv4.IMREAD_UNCHANGED);

  late final cv4.Mat rotated;
  switch (effective) {
    case 1:
      rotated = cv4.rotate(mat, cv4.ROTATE_90_CLOCKWISE);
    case 2:
      rotated = cv4.rotate(mat, cv4.ROTATE_180);
    case 3:
      rotated = cv4.rotate(mat, cv4.ROTATE_90_COUNTERCLOCKWISE);
    default:
      rotated = mat;
  }

  final encoded = cv4.imencode('.png', rotated);
  mat.dispose();
  if (!identical(rotated, mat)) rotated.dispose();
  return encoded.$2;
}

/// Converts [imageBytes] (PNG) to greyscale and returns PNG bytes.
Future<Uint8List> toGrayscale(Uint8List imageBytes) async {
  final mat = cv4.imdecode(imageBytes, cv4.IMREAD_COLOR);
  final gray = cv4.cvtColor(mat, cv4.COLOR_BGR2GRAY);

  final encoded = cv4.imencode('.png', gray);
  mat.dispose();
  gray.dispose();
  return encoded.$2;
}

/// Converts [imageBytes] (PNG) to pure black-and-white using adaptive
/// thresholding and returns PNG bytes.
///
/// [constant] is the value subtracted from the mean in adaptive thresholding.
/// Higher values produce more black; lower values produce more white.
/// Typical range: 2–30, default 10.
Future<Uint8List> toBlackAndWhite(
  Uint8List imageBytes, {
  double constant = 10,
}) async {
  final mat = cv4.imdecode(imageBytes, cv4.IMREAD_COLOR);
  final gray = cv4.cvtColor(mat, cv4.COLOR_BGR2GRAY);

  // Adaptive threshold handles varying lighting across the document.
  final bw = cv4.adaptiveThreshold(
    gray,
    255,
    cv4.ADAPTIVE_THRESH_GAUSSIAN_C,
    cv4.THRESH_BINARY,
    15, // block size
    constant, // constant subtracted from the mean
  );

  final encoded = cv4.imencode('.png', bw);
  mat.dispose();
  gray.dispose();
  bw.dispose();
  return encoded.$2;
}

/// Enhances a document image for improved text readability.
///
/// Pipeline optimised for black text on white/light backgrounds:
///   1. Light bilateral filter to reduce camera noise while preserving
///      text edges.
///   2. Aggressive unsharp-mask sharpening (matching GIMP's enhance filter
///      with radius ≈ 6.8, amount ≈ 2.69, threshold 0) to make text
///      strokes crisp.
///
/// Returns the enhanced image as PNG-encoded bytes.
Future<Uint8List> autoEnhance(Uint8List imageBytes) async {
  final mat = cv4.imdecode(imageBytes, cv4.IMREAD_COLOR);

  // 1. Light denoising — bilateral filter keeps text edges sharp while
  //    smoothing camera sensor noise in flat areas (paper background).
  final denoised = await cv4.bilateralFilterAsync(mat, 5, 40, 40);
  mat.dispose();

  // 2. Unsharp mask — GIMP-style: result = src + amount * (src - blur).
  //    Equivalent to addWeighted(src, 1+amount, blur, -amount, 0).
  //    GIMP parameters: radius=6.8 → sigma≈3.4, amount=2.69, threshold=0.
  //    Kernel size (0,0) lets OpenCV derive it from sigma automatically.
  final blurred = await cv4.gaussianBlurAsync(denoised, (0, 0), 3.4);
  final sharpened = await cv4.addWeightedAsync(
    denoised,
    3.69, // 1 + amount
    blurred,
    -2.69, // -amount
    0,
  );
  denoised.dispose();
  blurred.dispose();

  final encoded = cv4.imencode('.png', sharpened);
  sharpened.dispose();
  return encoded.$2;
}

/// Generates a thumbnail of [imageBytes] (PNG) with a maximum dimension of
/// [maxDimension] pixels (preserving the aspect ratio).
///
/// Returns the resized image as PNG-encoded bytes.
Future<Uint8List> generateThumbnail(
  Uint8List imageBytes, {
  int maxDimension = 200,
}) async {
  final mat = cv4.imdecode(imageBytes, cv4.IMREAD_COLOR);
  final w = mat.width;
  final h = mat.height;
  final maxDim = w > h ? w : h;

  if (maxDim <= maxDimension) {
    final encoded = cv4.imencode('.png', mat);
    mat.dispose();
    return encoded.$2;
  }

  final scale = maxDimension / maxDim;
  final newW = (w * scale).round();
  final newH = (h * scale).round();
  final resized = await cv4.resizeAsync(mat, (newW, newH));

  final encoded = cv4.imencode('.png', resized);
  mat.dispose();
  resized.dispose();
  return encoded.$2;
}
