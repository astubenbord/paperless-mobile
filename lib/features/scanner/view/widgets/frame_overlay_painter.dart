import 'package:flutter/material.dart';
import 'package:paperless_mobile/features/scanner/models/document_frame.dart';

class FrameOverlayPainter extends CustomPainter {
  final Color frameColor;
  final DocumentFrame frame;
  final Size imageSize;

  FrameOverlayPainter({
    required this.frame,
    required this.imageSize,
    required this.frameColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Replicate the BoxFit.cover transform used by FocusableCameraView:
    // uniform scale = max of the two axis scales, then center (crop overflow).
    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;
    final scale = scaleX > scaleY ? scaleX : scaleY;
    final offsetX = (size.width - imageSize.width * scale) / 2;
    final offsetY = (size.height - imageSize.height * scale) / 2;

    final paint = Paint()
      ..color = frameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final corners = [
      frame.topLeft,
      frame.topRight,
      frame.bottomRight,
      frame.bottomLeft,
    ];

    final path = Path();
    final first = corners.first;
    path.moveTo(first.dx * scale + offsetX, first.dy * scale + offsetY);
    for (final point in corners.skip(1)) {
      path.lineTo(point.dx * scale + offsetX, point.dy * scale + offsetY);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant FrameOverlayPainter oldDelegate) => true;
}
