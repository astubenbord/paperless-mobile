import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';

/// A spirit level overlay that helps the user hold the device parallel to the
/// ground for better scan results.
///
/// A small bubble dot drifts toward a fixed target dot at the centre. Both
/// use the current Material You colour scheme. The overlay fades in when
/// the device is within [_visibilityThresholdDeg] and the target ring
/// highlights when alignment is within [_levelThresholdDeg].
class SpiritLevelWidget extends StatefulWidget {
  const SpiritLevelWidget({super.key});

  @override
  State<SpiritLevelWidget> createState() => _SpiritLevelWidgetState();
}

class _SpiritLevelWidgetState extends State<SpiritLevelWidget>
    with SingleTickerProviderStateMixin {
  static const _visibilityThresholdDeg = 5.0;
  static const _levelThresholdDeg = 5.0;
  static const _snapThresholdDeg = 0.6;
  static const _maxOffsetPx = 50.0;
  static const _smoothingFactor = 0.1;

  /// Snap vibration parameters.
  static const _snapDurationMs = 40;
  static const _snapAmplitude = 255;

  StreamSubscription<AccelerometerEvent>? _subscription;

  double _smoothedRollDeg = 0;
  double _smoothedPitchDeg = 0;
  bool _hasSnapped = false;

  late final AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _subscription = accelerometerEventStream(
      samplingPeriod: SensorInterval.uiInterval,
    ).listen(_onAccelerometerEvent);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  void _onAccelerometerEvent(AccelerometerEvent event) {
    final rollDeg = math.atan2(event.x, event.z) * 180 / math.pi;
    final pitchDeg = math.atan2(event.y, event.z) * 180 / math.pi;

    _smoothedRollDeg += _smoothingFactor * (rollDeg - _smoothedRollDeg);
    _smoothedPitchDeg += _smoothingFactor * (pitchDeg - _smoothedPitchDeg);

    final isVisible =
        _smoothedRollDeg.abs() < _visibilityThresholdDeg &&
        _smoothedPitchDeg.abs() < _visibilityThresholdDeg;

    if (isVisible && !_fadeController.isCompleted) {
      _fadeController.forward();
    } else if (!isVisible && _fadeController.value > 0) {
      _fadeController.reverse();
    }

    // Snap vibration when entering the centre tolerance.
    final isSnapped =
        _smoothedRollDeg.abs() < _snapThresholdDeg &&
        _smoothedPitchDeg.abs() < _snapThresholdDeg;
    if (isSnapped && !_hasSnapped) {
      Vibration.vibrate(
        duration: _snapDurationMs,
        amplitude: _snapAmplitude,
        sharpness: 1.0,
      );
    }
    _hasSnapped = isSnapped;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Compute raw pixel offset from smoothed sensor values.
    var dx =
        (-_smoothedRollDeg / _visibilityThresholdDeg).clamp(-1.0, 1.0) *
        _maxOffsetPx;
    var dy =
        (_smoothedPitchDeg / _visibilityThresholdDeg).clamp(-1.0, 1.0) *
        _maxOffsetPx;

    // Snap to centre when nearly level.
    if (_smoothedRollDeg.abs() < _snapThresholdDeg &&
        _smoothedPitchDeg.abs() < _snapThresholdDeg) {
      dx = 0;
      dy = 0;
    }

    return FadeTransition(
      opacity: _fadeController,
      child: CustomPaint(
        painter: _SpiritLevelPainter(
          bubbleOffset: Offset(dx, dy),
          isInZone:
              _smoothedRollDeg.abs() < _levelThresholdDeg &&
              _smoothedPitchDeg.abs() < _levelThresholdDeg,
          maxOffsetPx: _maxOffsetPx,
          visibilityThresholdDeg: _visibilityThresholdDeg,
          levelThresholdDeg: _levelThresholdDeg,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class _SpiritLevelPainter extends CustomPainter {
  _SpiritLevelPainter({
    required this.bubbleOffset,
    required this.isInZone,
    required this.maxOffsetPx,
    required this.visibilityThresholdDeg,
    required this.levelThresholdDeg,
  });

  // Hardcoded colours for good contrast on white paper / dark backgrounds.
  static final _centerColor = Colors.amber; // centre crosshair + ring
  static const _bubbleColor = Colors.white; // pointer crosshair + ring

  /// Pre-computed bubble offset from centre.
  final Offset bubbleOffset;
  final bool isInZone;
  final double maxOffsetPx;
  final double visibilityThresholdDeg;
  final double levelThresholdDeg;

  /// Half-length of each crosshair arm.
  static const _armLength = 8.0;

  /// Pixel radius that corresponds to [levelThresholdDeg].
  double get _targetRadius =>
      maxOffsetPx * (levelThresholdDeg / visibilityThresholdDeg);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);

    final bubbleCenter = center + bubbleOffset;
    final distancePx = bubbleOffset.distance;

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = _bubbleColor.withValues(alpha: isInZone ? 0.5 : 0.2);
    canvas.drawCircle(center, _targetRadius, ringPaint);

    _drawCrosshair(
      canvas,
      bubbleCenter,
      _armLength,
      _bubbleColor.withValues(alpha: 0.9),
      strokeWidth: 1.5,
    );

    final bubblePaint = Paint()..color = _bubbleColor.withValues(alpha: 0.9);
    canvas.drawCircle(bubbleCenter, 2.0, bubblePaint);

    // -- Centre crosshair (fixed target, amber — always on top) --
    _drawCrosshair(
      canvas,
      center,
      _armLength,
      _centerColor.withValues(alpha: isInZone ? 0.9 : 0.6),
      strokeWidth: 1.5,
    );

    final centerDotPaint = Paint()
      ..color = _centerColor.withValues(alpha: isInZone ? 0.9 : 0.6);
    canvas.drawCircle(center, 2.0, centerDotPaint);

    // -- Subtle glow when level --
    if (isInZone) {
      final levelRatio = (1.0 - (distancePx / _targetRadius)).clamp(0.0, 1.0);
      if (levelRatio > 0.3) {
        final glowPaint = Paint()
          ..color = _centerColor.withValues(alpha: 0.10 * levelRatio)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
        canvas.drawCircle(center, _targetRadius * 0.7, glowPaint);
      }
    }
  }

  void _drawCrosshair(
    Canvas canvas,
    Offset center,
    double arm,
    Color color, {
    double strokeWidth = 2.0,
  }) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center + Offset(-arm, 0), center + Offset(arm, 0), paint);
    canvas.drawLine(center + Offset(0, -arm), center + Offset(0, arm), paint);
  }

  @override
  bool shouldRepaint(_SpiritLevelPainter oldDelegate) =>
      bubbleOffset != oldDelegate.bubbleOffset ||
      isInZone != oldDelegate.isInZone;
}
