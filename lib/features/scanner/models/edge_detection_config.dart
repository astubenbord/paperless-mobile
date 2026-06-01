/// Configuration for the document edge detection algorithm.
///
/// Two presets are provided:
/// * [EdgeDetectionConfig.fast] — optimized for live camera preview
///   (moderately downscaled to keep overlays responsive without shrinking
///   corners too aggressively).
/// * [EdgeDetectionConfig.accurate] — optimized for a captured still image
///   (larger processing resolution, finer morphology kernels, tighter
///   approximation epsilon).
class EdgeDetectionConfig {
  /// Maximum dimension (in pixels) to which the image is downscaled before
  /// processing. Larger values give more precise contour detection at the
  /// cost of speed.
  final int resizeThreshold;

  /// Border padding (pixels) added around the resized image so documents
  /// touching the frame edges can still be found.
  final int borderSize;

  /// Median blur kernel size (must be odd). Larger values remove more noise
  /// but may erase thin document edges.
  final int medianBlurKernel;

  /// Polygon approximation factor (fraction of arc-length used as epsilon).
  /// Smaller values require the contour to match a perfect quad more closely.
  final double approxEpsilonFactor;

  /// Morphological close kernel size. Smaller values preserve finer detail.
  final int morphologyKernel;

  /// Dilate kernel size.
  final int dilateKernel;

  /// Minimum contour area as a fraction of the (resized) image area.
  final double minAreaFactor;

  const EdgeDetectionConfig({
    required this.resizeThreshold,
    this.borderSize = 10,
    this.medianBlurKernel = 9,
    this.approxEpsilonFactor = 0.02,
    this.morphologyKernel = 4,
    this.dilateKernel = 3,
    this.minAreaFactor = 0.04,
  });

  /// Fast preset: tuned for live preview.
  ///
  /// Compared with the still-image pipeline, this keeps substantially fewer
  /// pixels for throughput, but avoids an extreme downscaling that
  /// tended to pull corners slightly inward after scaling back up.
  static const fast = EdgeDetectionConfig(
    resizeThreshold: 320,
    medianBlurKernel: 7,
    approxEpsilonFactor: 0.018,
    morphologyKernel: 3,
    dilateKernel: 2,
    minAreaFactor: 0.03,
  );

  /// Accurate preset: processes at a higher resolution with finer parameters,
  /// suitable for a captured still image where speed is less critical.
  static const accurate = EdgeDetectionConfig(
    resizeThreshold: 600,
    medianBlurKernel: 5,
    approxEpsilonFactor: 0.015,
    morphologyKernel: 3,
    dilateKernel: 2,
    minAreaFactor: 0.02,
  );
}
