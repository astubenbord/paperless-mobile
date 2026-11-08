import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:paperless_mobile/features/scanner/models/document_frame.dart';

/// Paints a Material-style circular "ink fill" that grows from the center
/// of the detected document frame, clipped to the quad boundary.
///
/// [progress] ranges from 0.0 (nothing visible) to 1.0 (fully filled).
/// The circle grows from the frame's center outward.
class AutoCaptureOverlayPainter extends CustomPainter {
  final DocumentFrame frame;
  final Size imageSize;
  final double progress;
  final Color fillColor;

  AutoCaptureOverlayPainter({
    required this.frame,
    required this.imageSize,
    required this.progress,
    this.fillColor = const Color(0x4000E676),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    // --- Coordinate transform (same as FrameOverlayPainter) ---
    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;
    final scale = math.max(scaleX, scaleY);
    final offsetX = (size.width - imageSize.width * scale) / 2;
    final offsetY = (size.height - imageSize.height * scale) / 2;

    Offset transform(Offset pt) =>
        Offset(pt.dx * scale + offsetX, pt.dy * scale + offsetY);

    final tl = transform(frame.topLeft);
    final tr = transform(frame.topRight);
    final br = transform(frame.bottomRight);
    final bl = transform(frame.bottomLeft);

    // Build quad path.
    final quadPath = Path()
      ..moveTo(tl.dx, tl.dy)
      ..lineTo(tr.dx, tr.dy)
      ..lineTo(br.dx, br.dy)
      ..lineTo(bl.dx, bl.dy)
      ..close();

    // Center of the quad in widget coordinates.
    final center = Offset(
      (tl.dx + tr.dx + br.dx + bl.dx) / 4,
      (tl.dy + tr.dy + br.dy + bl.dy) / 4,
    );

    // Max radius = distance from center to the farthest corner.
    final maxRadius = [
      (tl - center).distance,
      (tr - center).distance,
      (br - center).distance,
      (bl - center).distance,
    ].reduce(math.max);

    final currentRadius = maxRadius * progress;

    // Clip to the quad and draw a growing circle.
    canvas.save();
    canvas.clipPath(quadPath);

    final paint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, currentRadius, paint);

    // Draw a subtle ring at the edge of the growing circle for
    // a crisper "ink wave" look.
    if (progress < 1.0) {
      final ringPaint = Paint()
        ..color = fillColor.withValues(alpha: fillColor.a * 1.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawCircle(center, currentRadius, ringPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant AutoCaptureOverlayPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.frame != frame ||
        oldDelegate.fillColor != fillColor;
  }
}
