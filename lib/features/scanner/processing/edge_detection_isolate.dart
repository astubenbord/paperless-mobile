import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';

import 'package:opencv_dart/opencv_dart.dart' as cv4;
import 'package:paperless_mobile/features/scanner/models/document_frame.dart';
import 'package:paperless_mobile/features/scanner/processing/detect_edges.dart';
import 'package:paperless_mobile/features/scanner/models/edge_detection_config.dart';

/// Result from background edge detection.
sealed class DetectionOutcome {}

/// Frame was successfully detected.
class FrameDetected extends DetectionOutcome {
  final DocumentFrame frame;
  final Size imageSize;
  FrameDetected(this.frame, this.imageSize);
}

/// Frame was processed but no document was found.
class FrameNotFound extends DetectionOutcome {}

/// Runs document edge detection on a persistent background [Isolate].
///
/// Provides automatic frame skipping: if a previous detection is still
/// in-flight, new [detect] calls return `null` immediately without blocking.
/// A non-null return distinguishes "found" from "not found".
class EdgeDetectionRunner {
  Isolate? _isolate;
  SendPort? _workerSendPort;
  bool _isProcessing = false;
  final _initCompleter = Completer<void>();

  bool get isProcessing => _isProcessing;

  /// Spawns the background isolate. Must be called before [detect].
  Future<void> start() async {
    final receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_workerEntryPoint, receivePort.sendPort);
    _workerSendPort = await receivePort.first as SendPort;
    _initCompleter.complete();
  }

  /// Submits RGBA image data for edge detection.
  ///
  /// Returns `null` when the previous frame is still being processed
  /// (frame skipping — caller should ignore). Otherwise returns a
  /// [DetectionOutcome] indicating found or not-found.
  Future<DetectionOutcome?> detect({
    required Uint8List rgbaBytes,
    required int width,
    required int height,
    required int rotationCompensation,
    required EdgeDetectionConfig edgeDetectionConfig,
  }) async {
    if (_isProcessing) return null;
    await _initCompleter.future;
    if (_workerSendPort == null) return null;

    _isProcessing = true;
    try {
      final replyPort = ReceivePort();
      _workerSendPort!.send([
        rgbaBytes,
        width,
        height,
        rotationCompensation,
        replyPort.sendPort,
        edgeDetectionConfig,
      ]);

      final result = await replyPort.first;
      replyPort.close();

      if (result == null) return FrameNotFound();
      final data = (result as List).cast<double>();
      // [imgW, imgH, tl.dx, tl.dy, tr.dx, tr.dy, br.dx, br.dy, bl.dx, bl.dy]
      return FrameDetected(
        DocumentFrame(
          topLeft: Offset(data[2], data[3]),
          topRight: Offset(data[4], data[5]),
          bottomRight: Offset(data[6], data[7]),
          bottomLeft: Offset(data[8], data[9]),
        ),
        Size(data[0], data[1]),
      );
    } finally {
      _isProcessing = false;
    }
  }

  void dispose() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _workerSendPort = null;
  }

  // ---------------------------------------------------------------------------
  // Isolate entry point & processing
  // ---------------------------------------------------------------------------

  static void _workerEntryPoint(SendPort mainSendPort) {
    final workerReceivePort = ReceivePort();
    mainSendPort.send(workerReceivePort.sendPort);

    workerReceivePort.listen((message) async {
      final msg = message as List;
      final Uint8List rgbaBytes = msg[0];
      final int width = msg[1];
      final int height = msg[2];
      final int rotationCompensation = msg[3];
      final SendPort replyPort = msg[4];
      final EdgeDetectionConfig config = msg[5] as EdgeDetectionConfig;

      try {
        final result = await _processFrame(
          rgbaBytes,
          width,
          height,
          rotationCompensation,
          config,
        );
        replyPort.send(result);
      } catch (_) {
        replyPort.send(null);
      }
    });
  }

  static Future<List<double>?> _processFrame(
    Uint8List rgbaBytes,
    int width,
    int height,
    int rotationCompensation,
    EdgeDetectionConfig config,
  ) async {
    cv4.Mat mat = cv4.Mat.fromList(
      height,
      width,
      cv4.MatType.CV_8UC4,
      rgbaBytes,
    );

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
    }

    final (frame, _) = await detectDocumentEdges(mat, config: config);
    final imgW = mat.cols.toDouble();
    final imgH = mat.rows.toDouble();
    mat.dispose();

    if (frame == null) return null;
    return [
      imgW,
      imgH,
      frame.topLeft.dx,
      frame.topLeft.dy,
      frame.topRight.dx,
      frame.topRight.dy,
      frame.bottomRight.dx,
      frame.bottomRight.dy,
      frame.bottomLeft.dx,
      frame.bottomLeft.dy,
    ];
  }
}
