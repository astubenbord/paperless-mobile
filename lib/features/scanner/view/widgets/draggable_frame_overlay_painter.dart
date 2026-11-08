import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:paperless_mobile/features/scanner/models/document_frame.dart';

/// Paints the edge overlay with draggable corner handles on the captured image.
///
/// When [activeCornerIndex] is set (0-3 for TL/TR/BR/BL), the active corner is
/// replaced by a magnifier loupe showing the zoomed image region around that
/// corner, with the two adjacent edges drawn inside the loupe.
class DraggableFrameOverlayPainter extends CustomPainter {
  final DocumentFrame frame;
  final Size imageSize;
  final Color frameColor;

  /// Index of the corner currently being dragged (0=TL, 1=TR, 2=BR, 3=BL),
  /// or `null` when no corner is active.
  final int? activeCornerIndex;

  /// The source image used for the magnifier. Required when
  /// [activeCornerIndex] is non-null.
  final ui.Image? sourceImage;

  /// The finger position used to place the magnifier during precision mode.
  final Offset? magnifierAnchor;

  /// Radius of the inactive corner circles.
  static const double cornerRadius = 14.0;

  /// Radius of the magnifier loupe.
  static const double _loupeRadius = 80.0;

  /// How much the image is zoomed inside the loupe.
  static const double _loupeZoom = 2.0;

  DraggableFrameOverlayPainter({
    required this.frame,
    required this.imageSize,
    required this.frameColor,
    this.activeCornerIndex,
    this.magnifierAnchor,
    this.sourceImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Scale from image coordinates to widget coordinates using BoxFit.contain.
    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    final offsetX = (size.width - imageSize.width * scale) / 2;
    final offsetY = (size.height - imageSize.height * scale) / 2;

    Offset transform(Offset p) =>
        Offset(p.dx * scale + offsetX, p.dy * scale + offsetY);

    final imageCorners = [
      frame.topLeft,
      frame.topRight,
      frame.bottomRight,
      frame.bottomLeft,
    ];
    final corners = imageCorners.map(transform).toList();

    // Draw semi-transparent overlay outside the selection.
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.4);
    final fullRect = Offset.zero & size;
    final quadPath = Path()
      ..moveTo(corners[0].dx, corners[0].dy)
      ..lineTo(corners[1].dx, corners[1].dy)
      ..lineTo(corners[2].dx, corners[2].dy)
      ..lineTo(corners[3].dx, corners[3].dy)
      ..close();
    final overlayPath = Path.combine(
      PathOperation.difference,
      Path()..addRect(fullRect),
      quadPath,
    );
    canvas.drawPath(overlayPath, overlayPaint);

    // Draw the quad outline.
    final linePaint = Paint()
      ..color = frameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawPath(quadPath, linePaint);

    // Draw corner handles.
    final fillPaint = Paint()
      ..color = frameColor
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (var i = 0; i < corners.length; i++) {
      if (i == activeCornerIndex && sourceImage != null) {
        _drawMagnifier(canvas, size, corners[i], imageCorners[i], i, corners);
      } else {
        canvas.drawCircle(corners[i], cornerRadius, fillPaint);
        canvas.drawCircle(corners[i], cornerRadius, borderPaint);
      }
    }
  }

  /// Draws a magnifier loupe at [widgetPos] showing a zoomed region of the
  /// source image centered on [imagePos]. The two edges adjacent to the active
  /// corner are drawn inside the loupe so the user can see the contour.
  void _drawMagnifier(
    Canvas canvas,
    Size canvasSize,
    Offset widgetPos,
    Offset imagePos,
    int cornerIdx,
    List<Offset> widgetCorners,
  ) {
    final r = _loupeRadius;
    final anchor = magnifierAnchor ?? widgetPos;
    final magnifierCenter = Offset(
      anchor.dx.clamp(r, canvasSize.width - r),
      (anchor.dy - r - 30).clamp(r, canvasSize.height - r - 30),
    );

    // Clip to a circle.
    canvas.save();
    final loupePath = Path()
      ..addOval(Rect.fromCircle(center: magnifierCenter, radius: r));
    canvas.clipPath(loupePath);

    // Draw the zoomed portion of the source image.
    // The region in the source image that maps into the loupe.
    final srcRegionHalf = r / _loupeZoom;
    // Source rect in image pixels.
    final srcRect = Rect.fromCenter(
      center: imagePos,
      width: srcRegionHalf * 2 / 1.0, // in image coords
      height: srcRegionHalf * 2 / 1.0,
    );
    final dstRect = Rect.fromCircle(center: magnifierCenter, radius: r);

    canvas.drawImageRect(
      sourceImage!,
      srcRect,
      dstRect,
      Paint()..filterQuality = FilterQuality.medium,
    );

    // Draw the two adjacent edges inside the loupe.
    // For corner i, the adjacent corners are (i-1)%4 and (i+1)%4.
    final prevIdx = (cornerIdx - 1) % 4;
    final nextIdx = (cornerIdx + 1) % 4;

    // Transform edge endpoints into loupe-local coordinates:
    // widgetPos maps to center, with zoom factor applied.
    Offset toLoupeSpace(Offset wp) {
      return Offset(
        magnifierCenter.dx + (wp.dx - widgetPos.dx) * _loupeZoom,
        magnifierCenter.dy + (wp.dy - widgetPos.dy) * _loupeZoom,
      );
    }

    final edgePaint = Paint()
      ..color = frameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final activeCenter = toLoupeSpace(widgetCorners[cornerIdx]);
    final prevPoint = toLoupeSpace(widgetCorners[prevIdx]);
    final nextPoint = toLoupeSpace(widgetCorners[nextIdx]);

    canvas.drawLine(activeCenter, prevPoint, edgePaint);
    canvas.drawLine(activeCenter, nextPoint, edgePaint);

    canvas.restore();

    // Draw loupe border.
    final loupeBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(magnifierCenter, r, loupeBorderPaint);

    // Draw crosshair at center.
    final crossPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    const crossSize = 8.0;
    canvas.drawLine(
      Offset(magnifierCenter.dx - crossSize, magnifierCenter.dy),
      Offset(magnifierCenter.dx + crossSize, magnifierCenter.dy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(magnifierCenter.dx, magnifierCenter.dy - crossSize),
      Offset(magnifierCenter.dx, magnifierCenter.dy + crossSize),
      crossPaint,
    );
  }

  @override
  bool shouldRepaint(covariant DraggableFrameOverlayPainter oldDelegate) {
    return oldDelegate.frame != frame ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.frameColor != frameColor ||
        oldDelegate.activeCornerIndex != activeCornerIndex ||
        oldDelegate.magnifierAnchor != magnifierAnchor ||
        oldDelegate.sourceImage != sourceImage;
  }
}
