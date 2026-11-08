import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

extension CvMatUiImageExtension on cv.Mat {
  Future<ui.Image> toUiImage({
    ui.PixelFormat format = ui.PixelFormat.rgba8888,
  }) async {
    final immutable = await ui.ImmutableBuffer.fromUint8List(data);
    ui.ImageDescriptor desc = ui.ImageDescriptor.raw(
      immutable,
      width: width,
      height: height,
      pixelFormat: format,
    );
    final codec = await desc.instantiateCodec();
    final frame = await codec.getNextFrame();
    return frame.image;
  }
}

Uint8List yuv420ToNV21(CameraImage image) {
  final width = image.width;
  final height = image.height;
  // Planes from CameraImage
  final yPlane = image.planes[0];
  final uPlane = image.planes[1];
  final vPlane = image.planes[2];
  // Buffers from Y, U, and V planes
  final yBuffer = yPlane.bytes;
  final uBuffer = uPlane.bytes;
  final vBuffer = vPlane.bytes;
  // Total number of pixels in NV21 format
  final numPixels = width * height + (width * height ~/ 2);
  final nv21 = Uint8List(numPixels);
  // Y (Luma) plane metadata
  int idY = 0;
  int idUV = width * height; // Start UV after Y plane
  final uvWidth = width ~/ 2;
  final uvHeight = height ~/ 2;
  // Strides and pixel strides for Y and UV planes
  final yRowStride = yPlane.bytesPerRow;
  final yPixelStride = yPlane.bytesPerPixel ?? 1;
  final uvRowStride = uPlane.bytesPerRow;
  final uvPixelStride = uPlane.bytesPerPixel ?? 2;
  // Copy Y (Luma) channel
  for (int y = 0; y < height; ++y) {
    final yOffset = y * yRowStride;
    for (int x = 0; x < width; ++x) {
      nv21[idY++] = yBuffer[yOffset + x * yPixelStride];
    }
  }
  // Copy UV (Chroma) channels in NV21 format (YYYYVU interleaved)
  for (int y = 0; y < uvHeight; ++y) {
    final uvOffset = y * uvRowStride;
    for (int x = 0; x < uvWidth; ++x) {
      final bufferIndex = uvOffset + (x * uvPixelStride);
      nv21[idUV++] = vBuffer[bufferIndex]; // V channel
      nv21[idUV++] = uBuffer[bufferIndex]; // U channel
    }
  }
  return nv21;
}

Uint8List yuv420ToRGBA8888(CameraImage image) {
  final int width = image.width;
  final int height = image.height;

  final int uvRowStride = image.planes[1].bytesPerRow;
  final int uvPixelStride = image.planes[1].bytesPerPixel!;

  final int yRowStride = image.planes[0].bytesPerRow;
  final int yPixelStride = image.planes[0].bytesPerPixel!;

  final yBuffer = image.planes[0].bytes;
  final uBuffer = image.planes[1].bytes;
  final vBuffer = image.planes[2].bytes;

  final rgbaBuffer = Uint8List(width * height * 4);

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final int uvIndex =
          uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
      final int index = y * width + x;

      final yValue = yBuffer[y * yRowStride + x * yPixelStride];
      final uValue = uBuffer[uvIndex];
      final vValue = vBuffer[uvIndex];

      final r = (yValue + 1.402 * (vValue - 128)).round();
      final g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
          .round();
      final b = (yValue + 1.772 * (uValue - 128)).round();

      rgbaBuffer[index * 4 + 0] = r.clamp(0, 255);
      rgbaBuffer[index * 4 + 1] = g.clamp(0, 255);
      rgbaBuffer[index * 4 + 2] = b.clamp(0, 255);
      rgbaBuffer[index * 4 + 3] = 255;
    }
  }
  return rgbaBuffer;
}

Uint8List nv21ToRGBA8888(CameraImage image) {
  final int width = image.width;
  final int height = image.height;
  final int frameSize = width * height;
  final rgbaBuffer = Uint8List(frameSize * 4);
  final bytes = image.planes[0].bytes;

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final int yIndex = y * width + x;
      final int uvIndex = frameSize + (y >> 1) * width + (x >> 1) * 2;

      final yValue = bytes[yIndex];
      final vValue = bytes[uvIndex]; // V first in NV21
      final uValue = bytes[uvIndex + 1]; // U second

      final r = (yValue + 1.402 * (vValue - 128)).round();
      final g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
          .round();
      final b = (yValue + 1.772 * (uValue - 128)).round();

      final int index = yIndex * 4;
      rgbaBuffer[index + 0] = r.clamp(0, 255);
      rgbaBuffer[index + 1] = g.clamp(0, 255);
      rgbaBuffer[index + 2] = b.clamp(0, 255);
      rgbaBuffer[index + 3] = 255;
    }
  }

  return rgbaBuffer;
}

Uint8List bgraToRgbaInPlace(Uint8List bgra) {
  final out = Uint8List(bgra.length);
  for (int i = 0; i < bgra.length; i += 4) {
    out[i] = bgra[i + 2]; // R
    out[i + 1] = bgra[i + 1]; // G
    out[i + 2] = bgra[i]; // B
    out[i + 3] = bgra[i + 3]; // A
  }
  return out;
}
