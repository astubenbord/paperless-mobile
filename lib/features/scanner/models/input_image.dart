// Adapted from
// https://github.com/flutter-ml/google_ml_kit_flutter/blob/master/packages/google_mlkit_commons/lib/src/input_image.dart

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

/// Image format that ML Kit takes to process the image.
class InputImage {
  /// The file path to the image.
  final String? filePath;

  /// The bytes of the image.
  final Uint8List? bytes;

  /// The type of image.
  final InputImageType type;

  /// The image data when creating an image of type = [InputImageType.bytes].
  final InputImageMetadata? metadata;

  InputImage._({this.filePath, this.bytes, required this.type, this.metadata});

  /// Creates an instance of [InputImage] from path of image stored in device.
  factory InputImage.fromFilePath(String path) {
    return InputImage._(filePath: path, type: InputImageType.file);
  }

  /// Creates an instance of [InputImage] by passing a file.
  factory InputImage.fromFile(File file) {
    return InputImage._(filePath: file.path, type: InputImageType.file);
  }

  /// Creates an instance of [InputImage] using bytes.
  factory InputImage.fromBytes({
    required Uint8List bytes,
    required InputImageMetadata metadata,
  }) {
    return InputImage._(
      bytes: bytes,
      type: InputImageType.bytes,
      metadata: metadata,
    );
  }

  /// Returns a json representation of an instance of [InputImage].
  Map<String, dynamic> toJson() => {
    'bytes': bytes,
    'type': type.name,
    'path': filePath,
    'metadata': metadata?.toJson(),
  };
}

/// The type of [InputImage].
enum InputImageType { file, bytes }

/// Data of image required when creating image from bytes.
class InputImageMetadata {
  /// Size of image.
  final Size size;

  /// Image rotation degree.
  ///
  /// Not used on iOS.
  final InputImageRotation rotation;

  /// Format of the input image.
  ///
  /// Android supports
  /// - [InputImageFormat.nv21]
  /// - [InputImageFormat.yuv_420_888]
  /// - [InputImageFormat.yv12]
  /// as described in [here](https://developers.google.com/android/reference/com/google/mlkit/vision/common/InputImage.ImageFormat).
  ///
  /// iOS supports
  /// - [InputImageFormat.yuv420]
  /// - [InputImageFormat.bgra8888]
  final InputImageFormat format;

  /// The row stride for color plane, in bytes.
  ///
  /// Not used on Android.
  final int bytesPerRow;

  /// Constructor to create an instance of [InputImageMetadata].
  InputImageMetadata({
    required this.size,
    required this.rotation,
    required this.format,
    required this.bytesPerRow,
  });

  /// Returns a json representation of an instance of [InputImageMetadata].
  Map<String, dynamic> toJson() => {
    'width': size.width,
    'height': size.height,
    'rotation': rotation.rawValue,
    'image_format': format.rawValue,
    'bytes_per_row': bytesPerRow,
  };
}

/// The camera rotation angle to be specified
enum InputImageRotation {
  rotation0deg,
  rotation90deg,
  rotation180deg,
  rotation270deg,
}

extension InputImageRotationValue on InputImageRotation {
  int get rawValue {
    switch (this) {
      case InputImageRotation.rotation0deg:
        return 0;
      case InputImageRotation.rotation90deg:
        return 90;
      case InputImageRotation.rotation180deg:
        return 180;
      case InputImageRotation.rotation270deg:
        return 270;
    }
  }

  static InputImageRotation? fromRawValue(int rawValue) {
    try {
      return InputImageRotation.values.firstWhere(
        (element) => element.rawValue == rawValue,
      );
    } catch (_) {
      return null;
    }
  }
}

/// To indicate the format of image while creating input image from bytes
enum InputImageFormat {
  /// Android only: https://developers.google.com/android/reference/com/google/mlkit/vision/common/InputImage#IMAGE_FORMAT_NV21
  nv21,

  /// Android only: https://developers.google.com/android/reference/com/google/mlkit/vision/common/InputImage#public-static-final-int-image_format_yv12
  yv12,

  /// Android only: https://developers.google.com/android/reference/com/google/mlkit/vision/common/InputImage#public-static-final-int-image_format_yuv_420_888
  yuv_420_888,

  /// iOS only: https://developer.apple.com/documentation/corevideo/kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
  yuv420,

  /// iOS only: https://developer.apple.com/documentation/corevideo/kcvpixelformattype_32bgra
  bgra8888,
}

extension InputImageFormatValue on InputImageFormat {
  // source: https://developers.google.com/android/reference/com/google/mlkit/vision/common/InputImage#constants
  int get rawValue {
    switch (this) {
      case InputImageFormat.nv21:
        return 17;
      case InputImageFormat.yv12:
        return 842094169;
      case InputImageFormat.yuv_420_888:
        return 35;
      case InputImageFormat.yuv420:
        return 875704438;
      case InputImageFormat.bgra8888:
        return 1111970369;
    }
  }

  static InputImageFormat? fromRawValue(int rawValue) {
    try {
      return InputImageFormat.values.firstWhere(
        (element) => element.rawValue == rawValue,
      );
    } catch (_) {
      return null;
    }
  }
}
