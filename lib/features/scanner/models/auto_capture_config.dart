/// Configuration for the auto-capture feature.
///
/// When enabled, the scanner automatically takes a picture once the detected
/// document frame has remained stable for [preStableDelay] + [stableDuration].
///
/// Stability is determined by comparing the maximum Euclidean distance between
/// corresponding corners of consecutive frames against [distanceThreshold].
///
/// The capture flow has two phases:
///   1. **Pre-delay**: After [minConsecutiveSimilarFrames] similar frames,
///      a grace period of [preStableDelay] must pass with the frame staying
///      stable. No visual progress is shown during this phase.
///   2. **Fill animation**: Once the pre-delay elapses the circular fill
///      animation runs for [stableDuration], after which the shutter fires.
class AutoCaptureConfig {
  /// Whether auto-capture is enabled.
  final bool enabled;

  /// How long the frame must remain stable *after* [preStableDelay]
  /// before the shutter fires.
  final Duration stableDuration;

  /// Grace period before the fill animation starts. The frame must stay
  /// stable during this time but no visual progress is shown yet.
  final Duration preStableDelay;

  /// Maximum Euclidean distance (in image-coordinate pixels) between any
  /// pair of corresponding corners for two frames to be considered "similar".
  final double distanceThreshold;

  /// Minimum number of consecutive similar frames required before the
  /// pre-delay timer starts. Avoids false triggers from a single lucky frame.
  final int minConsecutiveSimilarFrames;

  const AutoCaptureConfig({
    this.enabled = true,
    this.stableDuration = const Duration(milliseconds: 1000),
    this.preStableDelay = const Duration(milliseconds: 1000),
    this.distanceThreshold = 50.0,
    this.minConsecutiveSimilarFrames = 3,
  });

  const AutoCaptureConfig.disabled()
    : enabled = false,
      stableDuration = const Duration(milliseconds: 1000),
      preStableDelay = const Duration(milliseconds: 1000),
      distanceThreshold = 50.0,
      minConsecutiveSimilarFrames = 3;

  AutoCaptureConfig copyWith({
    bool? enabled,
    Duration? stableDuration,
    Duration? preStableDelay,
    double? distanceThreshold,
    int? minConsecutiveSimilarFrames,
  }) {
    return AutoCaptureConfig(
      enabled: enabled ?? this.enabled,
      stableDuration: stableDuration ?? this.stableDuration,
      preStableDelay: preStableDelay ?? this.preStableDelay,
      distanceThreshold: distanceThreshold ?? this.distanceThreshold,
      minConsecutiveSimilarFrames:
          minConsecutiveSimilarFrames ?? this.minConsecutiveSimilarFrames,
    );
  }
}
