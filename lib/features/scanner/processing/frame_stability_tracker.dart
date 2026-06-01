import 'package:paperless_mobile/features/scanner/models/auto_capture_config.dart';
import 'package:paperless_mobile/features/scanner/models/document_frame.dart';

/// Tracks whether the detected document frame has been stable long enough
/// to trigger auto-capture.
///
/// Uses a two-phase approach:
///   1. **Pre-delay phase**: After [AutoCaptureConfig.minConsecutiveSimilarFrames]
///      similar frames, a grace period of [AutoCaptureConfig.preStableDelay] runs.
///      [progress] stays at 0 during this phase.
///   2. **Fill phase**: Once the pre-delay elapses, [progress] ramps from 0 → 1
///      over [AutoCaptureConfig.stableDuration].
///
/// Similarity is checked using the maximum Euclidean distance across all four
/// corresponding corners (see [DocumentFrame.isSimilarTo]).
class FrameStabilityTracker {
  final AutoCaptureConfig config;

  FrameStabilityTracker(this.config);

  DocumentFrame? _referenceFrame;
  int _similarCount = 0;
  DateTime? _preDelayStart;
  DateTime? _fillStart;
  bool _captured = false;

  /// The current reference frame used for similarity comparisons.
  /// This is the frame that has been staying stable. Returns `null` when
  /// no stable tracking is active.
  DocumentFrame? get stableFrame => _referenceFrame;

  /// Current progress toward auto-capture, from 0.0 to 1.0.
  /// Returns 0 during the pre-delay phase, and ramps to 1.0 during the fill
  /// phase.
  double get progress {
    if (_fillStart == null) return 0.0;
    final elapsed = DateTime.now().difference(_fillStart!);
    final total = config.stableDuration.inMicroseconds;
    if (total <= 0) return 1.0;
    return (elapsed.inMicroseconds / total).clamp(0.0, 1.0);
  }

  /// Whether the frame has been stable for the full duration
  /// and capture should be triggered.
  bool get isReadyToCapture {
    if (_captured) return false;
    return progress >= 1.0;
  }

  /// Call once capture has been triggered so we don't re-fire.
  void markCaptured() {
    _captured = true;
  }

  /// Feed a new smoothed frame (or `null` when no frame is detected).
  /// Returns the current [progress] after the update.
  double update(DocumentFrame? frame) {
    if (!config.enabled || frame == null) {
      reset();
      return 0.0;
    }

    if (_referenceFrame != null &&
        frame.isSimilarTo(
          _referenceFrame!,
          maxDistance: config.distanceThreshold,
        )) {
      _similarCount++;

      if (_similarCount >= config.minConsecutiveSimilarFrames) {
        // Phase 1: start or continue the pre-delay.
        _preDelayStart ??= DateTime.now();

        // Phase 2: once pre-delay elapses, start the fill timer.
        if (_fillStart == null) {
          final preElapsed = DateTime.now().difference(_preDelayStart!);
          if (preElapsed >= config.preStableDelay) {
            _fillStart = DateTime.now();
          }
        }
      }
    } else {
      // Frame moved too much — restart tracking with the new frame.
      _referenceFrame = frame;
      _similarCount = 1;
      _preDelayStart = null;
      _fillStart = null;
      _captured = false;
    }

    return progress;
  }

  /// Reset all tracking state (e.g. when the user moves the device or
  /// switches modes).
  void reset() {
    _referenceFrame = null;
    _similarCount = 0;
    _preDelayStart = null;
    _fillStart = null;
    _captured = false;
  }
}
