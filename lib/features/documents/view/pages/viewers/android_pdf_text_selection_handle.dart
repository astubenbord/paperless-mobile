import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class AndroidPdfTextSelectionHandle extends StatelessWidget {
  static const double size = 22;

  final PdfTextSelectionAnchor anchor;
  final PdfViewerTextSelectionAnchorHandleState state;

  const AndroidPdfTextSelectionHandle({
    super.key,
    required this.anchor,
    required this.state,
  });

  static Offset offsetForAnchor(
    BuildContext context,
    PdfTextSelectionAnchor anchor,
    PdfViewerTextSelectionAnchorHandleState state,
  ) {
    if (anchor.type == PdfTextSelectionAnchorType.a) {
      return const Offset(0, size);
    }
    return Offset.zero;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        TextSelectionTheme.of(context).selectionHandleColor ??
        theme.colorScheme.primary;
    final variant = _variantFor(anchor);

    Widget handle = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AndroidPdfTextSelectionHandlePainter(
          color: color,
          elevation: switch (state) {
            PdfViewerTextSelectionAnchorHandleState.dragging => 3,
            PdfViewerTextSelectionAnchorHandleState.hover => 2,
            PdfViewerTextSelectionAnchorHandleState.normal => 1.5,
          },
        ),
      ),
    );

    if (variant == _AndroidPdfTextSelectionHandleVariant.left) {
      handle = Transform.rotate(angle: math.pi / 2, child: handle);
    }

    return handle;
  }

  _AndroidPdfTextSelectionHandleVariant _variantFor(
    PdfTextSelectionAnchor anchor,
  ) {
    switch (anchor.direction) {
      case PdfTextDirection.ltr:
      case PdfTextDirection.unknown:
        return anchor.type == PdfTextSelectionAnchorType.a
            ? _AndroidPdfTextSelectionHandleVariant.left
            : _AndroidPdfTextSelectionHandleVariant.right;
      case PdfTextDirection.rtl:
      case PdfTextDirection.vrtl:
        return anchor.type == PdfTextSelectionAnchorType.a
            ? _AndroidPdfTextSelectionHandleVariant.right
            : _AndroidPdfTextSelectionHandleVariant.left;
    }
  }
}

enum _AndroidPdfTextSelectionHandleVariant { left, right }

class _AndroidPdfTextSelectionHandlePainter extends CustomPainter {
  final Color color;
  final double elevation;

  const _AndroidPdfTextSelectionHandlePainter({
    required this.color,
    required this.elevation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final circle = Rect.fromCircle(
      center: Offset(radius, radius),
      radius: radius,
    );
    final stem = Rect.fromLTWH(0, 0, radius, radius);
    final path = Path()
      ..addOval(circle)
      ..addRect(stem);

    canvas.drawShadow(
      path,
      Colors.black.withValues(alpha: 0.35),
      elevation,
      true,
    );
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(
    covariant _AndroidPdfTextSelectionHandlePainter oldDelegate,
  ) {
    return oldDelegate.color != color || oldDelegate.elevation != elevation;
  }
}
