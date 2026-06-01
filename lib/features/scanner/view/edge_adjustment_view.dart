import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:paperless_mobile/features/scanner/models/document_frame.dart';
import 'package:paperless_mobile/features/scanner/processing/perspective_transform.dart';
import 'package:paperless_mobile/features/scanner/view/widgets/draggable_frame_overlay_painter.dart';

/// A view that displays a captured image with a pre-detected document frame.
///
/// The user can drag the 4 corner points to adjust the selection, then press
/// "Done" to apply a perspective transform that rectifies the selected region
/// into a proper rectangle.
class EdgeAdjustmentView extends StatefulWidget {
  /// Raw bytes (PNG/JPEG) of the captured image.
  final Uint8List imageBytes;

  /// The initial document frame (from live detection) to display.
  final DocumentFrame initialFrame;

  /// The size of the original image in pixels.
  final Size imageSize;

  /// Called when the user confirms the adjusted selection.
  /// Receives the perspective-transformed image as PNG bytes and the adjusted frame.
  final void Function(Uint8List transformedBytes, DocumentFrame adjustedFrame)
  onConfirmed;

  /// Called when the user cancels / goes back.
  final VoidCallback onCancelled;

  const EdgeAdjustmentView({
    super.key,
    required this.imageBytes,
    required this.initialFrame,
    required this.imageSize,
    required this.onConfirmed,
    required this.onCancelled,
  });

  @override
  State<EdgeAdjustmentView> createState() => _EdgeAdjustmentViewState();
}

enum _Corner { topLeft, topRight, bottomRight, bottomLeft }

class _EdgeAdjustmentViewState extends State<EdgeAdjustmentView> {
  late DocumentFrame _frame;
  bool _isProcessing = false;
  _Corner? _activeCorner;
  bool _isDraggingFrame = false;
  bool _isPrecisionMode = false;
  Offset _lastPrecisionOffsetFromOrigin = Offset.zero;
  Offset? _precisionTouchPosition;
  ui.Image? _decodedImage;

  @override
  void initState() {
    super.initState();
    _frame = widget.initialFrame;
    _decodeImage();
  }

  Future<void> _decodeImage() async {
    final image = await decodeImageFromList(widget.imageBytes);
    if (mounted) {
      setState(() => _decodedImage = image);
    }
  }

  @override
  void dispose() {
    _decodedImage?.dispose();
    super.dispose();
  }

  Future<void> _onDone() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final result = await perspectiveTransform(
        imageBytes: widget.imageBytes,
        frame: _frame,
      );
      widget.onConfirmed(result, _frame);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Transform failed: $e')));
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Adjust edges')),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: widget.onCancelled,
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            Row(
              spacing: 16,
              children: [
                IconButton(
                  onPressed: _isProcessing ? null : _resetFrameToScanBounds,
                  tooltip: 'Reset to scan bounds',
                  icon: const Icon(Icons.crop_free),
                ),
                FilledButton.icon(
                  onPressed: _onDone,
                  icon: _isProcessing
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.done),
                  label: Text('Done'),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          // Inset from screen edges so dragging corners doesn't trigger the
          // system back gesture.
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onPanStart: (details) => _onPanStart(details, constraints),
                onPanUpdate: (details) => _onPanUpdate(details, constraints),
                onPanEnd: (_) => _resetInteractionState(),
                onPanCancel: _resetInteractionState,
                onLongPressStart: (details) =>
                    _onLongPressStart(details, constraints),
                onLongPressMoveUpdate: (details) =>
                    _onLongPressMoveUpdate(details, constraints),
                onLongPressEnd: (_) => _resetInteractionState(),
                child: Stack(
                  children: [
                    // Rendered image.
                    Center(
                      child: Image.memory(
                        widget.imageBytes,
                        fit: BoxFit.contain,
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                      ),
                    ),
                    // Edge overlay with draggable corners.
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: DraggableFrameOverlayPainter(
                            frame: _frame,
                            imageSize: widget.imageSize,
                            frameColor: Theme.of(context).colorScheme.primary,
                            activeCornerIndex:
                                _isPrecisionMode && _activeCorner != null
                                ? _Corner.values.indexOf(_activeCorner!)
                                : null,
                            magnifierAnchor: _precisionTouchPosition,
                            sourceImage: _decodedImage,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Transforms image coordinates to widget coordinates using BoxFit.contain.
  Offset _imageToWidget(Offset imagePos, BoxConstraints constraints) {
    final size = Size(constraints.maxWidth, constraints.maxHeight);
    final scaleX = size.width / widget.imageSize.width;
    final scaleY = size.height / widget.imageSize.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    final offsetX = (size.width - widget.imageSize.width * scale) / 2;
    final offsetY = (size.height - widget.imageSize.height * scale) / 2;

    return Offset(imagePos.dx * scale + offsetX, imagePos.dy * scale + offsetY);
  }

  ({Map<_Corner, Offset> corners, _Corner closestCorner, double minDistance})
  _resolveTouchTarget(Offset touchPos, BoxConstraints constraints) {
    final corners = {
      _Corner.topLeft: _imageToWidget(_frame.topLeft, constraints),
      _Corner.topRight: _imageToWidget(_frame.topRight, constraints),
      _Corner.bottomRight: _imageToWidget(_frame.bottomRight, constraints),
      _Corner.bottomLeft: _imageToWidget(_frame.bottomLeft, constraints),
    };

    var closestCorner = _Corner.topLeft;
    var minDistance = double.infinity;

    for (final entry in corners.entries) {
      final dist = (entry.value - touchPos).distance;
      if (dist < minDistance) {
        minDistance = dist;
        closestCorner = entry.key;
      }
    }

    return (
      corners: corners,
      closestCorner: closestCorner,
      minDistance: minDistance,
    );
  }

  void _resetInteractionState() {
    if (!mounted) return;
    setState(() {
      _activeCorner = null;
      _isDraggingFrame = false;
      _isPrecisionMode = false;
      _lastPrecisionOffsetFromOrigin = Offset.zero;
      _precisionTouchPosition = null;
    });
  }

  DocumentFrame get _scanBoundaryFrame {
    return DocumentFrame(
      topLeft: Offset.zero,
      topRight: Offset(widget.imageSize.width, 0),
      bottomRight: Offset(widget.imageSize.width, widget.imageSize.height),
      bottomLeft: Offset(0, widget.imageSize.height),
    );
  }

  void _resetFrameToScanBounds() {
    if (_isProcessing) return;

    setState(() {
      _frame = _scanBoundaryFrame;
      _activeCorner = null;
      _isDraggingFrame = false;
      _isPrecisionMode = false;
      _lastPrecisionOffsetFromOrigin = Offset.zero;
      _precisionTouchPosition = null;
    });
  }

  void _onPanStart(DragStartDetails details, BoxConstraints constraints) {
    final touchPos = details.localPosition;

    final target = _resolveTouchTarget(touchPos, constraints);

    // If close to a corner, drag that corner.
    const cornerHitRadius = 40.0;
    if (target.minDistance <= cornerHitRadius) {
      setState(() {
        _activeCorner = target.closestCorner;
        _isDraggingFrame = false;
        _isPrecisionMode = false;
      });
      return;
    }

    // If inside the quadrilateral, drag the whole frame.
    final polygon = [
      target.corners[_Corner.topLeft]!,
      target.corners[_Corner.topRight]!,
      target.corners[_Corner.bottomRight]!,
      target.corners[_Corner.bottomLeft]!,
    ];
    if (_isPointInPolygon(touchPos, polygon)) {
      setState(() {
        _isDraggingFrame = true;
        _activeCorner = null;
        _isPrecisionMode = false;
      });
      return;
    }

    // Outside the frame, drag the nearest corner directly with no magnifier.
    setState(() {
      _activeCorner = target.closestCorner;
      _isDraggingFrame = false;
      _isPrecisionMode = false;
    });
  }

  void _onLongPressStart(
    LongPressStartDetails details,
    BoxConstraints constraints,
  ) {
    final touchPos = details.localPosition;
    final target = _resolveTouchTarget(touchPos, constraints);

    HapticFeedback.mediumImpact();
    setState(() {
      _activeCorner = target.closestCorner;
      _isDraggingFrame = false;
      _isPrecisionMode = true;
      _lastPrecisionOffsetFromOrigin = Offset.zero;
      _precisionTouchPosition = touchPos;
    });
  }

  void _onLongPressMoveUpdate(
    LongPressMoveUpdateDetails details,
    BoxConstraints constraints,
  ) {
    final delta = details.offsetFromOrigin - _lastPrecisionOffsetFromOrigin;
    _lastPrecisionOffsetFromOrigin = details.offsetFromOrigin;
    _precisionTouchPosition = details.localPosition;
    _onDragDelta(delta, constraints, dampingFactor: 0.1);
  }

  /// Ray-casting point-in-polygon test.
  bool _isPointInPolygon(Offset point, List<Offset> polygon) {
    var inside = false;
    for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final xi = polygon[i].dx, yi = polygon[i].dy;
      final xj = polygon[j].dx, yj = polygon[j].dy;
      if (((yi > point.dy) != (yj > point.dy)) &&
          (point.dx < (xj - xi) * (point.dy - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
    }
    return inside;
  }

  /// Returns whether the four corners of [frame] form a convex quadrilateral.
  ///
  /// Uses the cross-product sign of consecutive edge vectors. A polygon is
  /// convex iff all cross products have the same sign.
  bool _isConvexQuad(DocumentFrame frame) {
    final pts = [
      frame.topLeft,
      frame.topRight,
      frame.bottomRight,
      frame.bottomLeft,
    ];

    bool? positive;
    for (var i = 0; i < 4; i++) {
      final a = pts[i];
      final b = pts[(i + 1) % 4];
      final c = pts[(i + 2) % 4];
      final cross =
          (b.dx - a.dx) * (c.dy - b.dy) - (b.dy - a.dy) * (c.dx - b.dx);
      if (cross.abs() < 1e-6) continue; // collinear edge, skip
      final sign = cross > 0;
      if (positive == null) {
        positive = sign;
      } else if (sign != positive) {
        return false;
      }
    }
    return true;
  }

  void _onPanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    _onDragDelta(details.delta, constraints, dampingFactor: 1.0);
  }

  void _onDragDelta(
    Offset delta,
    BoxConstraints constraints, {
    required double dampingFactor,
  }) {
    if (_activeCorner == null && !_isDraggingFrame) return;

    final size = Size(constraints.maxWidth, constraints.maxHeight);
    final scaleX = size.width / widget.imageSize.width;
    final scaleY = size.height / widget.imageSize.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    final imageDelta = Offset(
      delta.dx / scale * dampingFactor,
      delta.dy / scale * dampingFactor,
    );

    if (_isDraggingFrame) {
      _moveEntireFrame(imageDelta);
      return;
    }

    final currentPos = switch (_activeCorner!) {
      _Corner.topLeft => _frame.topLeft,
      _Corner.topRight => _frame.topRight,
      _Corner.bottomRight => _frame.bottomRight,
      _Corner.bottomLeft => _frame.bottomLeft,
    };

    final newPos = Offset(
      (currentPos.dx + imageDelta.dx).clamp(0.0, widget.imageSize.width),
      (currentPos.dy + imageDelta.dy).clamp(0.0, widget.imageSize.height),
    );

    final candidate = DocumentFrame(
      topLeft: _activeCorner == _Corner.topLeft ? newPos : _frame.topLeft,
      topRight: _activeCorner == _Corner.topRight ? newPos : _frame.topRight,
      bottomRight: _activeCorner == _Corner.bottomRight
          ? newPos
          : _frame.bottomRight,
      bottomLeft: _activeCorner == _Corner.bottomLeft
          ? newPos
          : _frame.bottomLeft,
    );

    // Only accept the move if the quad stays convex.
    if (!_isConvexQuad(candidate)) return;

    setState(() {
      _frame = candidate;
    });
  }

  void _moveEntireFrame(Offset imageDelta) {
    final maxW = widget.imageSize.width;
    final maxH = widget.imageSize.height;

    // Clamp the delta so no corner goes out of bounds.
    var dx = imageDelta.dx;
    var dy = imageDelta.dy;
    for (final pt in [
      _frame.topLeft,
      _frame.topRight,
      _frame.bottomRight,
      _frame.bottomLeft,
    ]) {
      dx = dx.clamp(-pt.dx, maxW - pt.dx);
      dy = dy.clamp(-pt.dy, maxH - pt.dy);
    }

    final delta = Offset(dx, dy);
    setState(() {
      _frame = DocumentFrame(
        topLeft: _frame.topLeft + delta,
        topRight: _frame.topRight + delta,
        bottomRight: _frame.bottomRight + delta,
        bottomLeft: _frame.bottomLeft + delta,
      );
    });
  }
}
