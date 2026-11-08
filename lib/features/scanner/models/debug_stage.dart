/// Intermediate processing stages that can be visualized for debugging.
enum DebugStage {
  /// No debug output.
  none,

  /// Grayscale conversion of the input image.
  grayscale,

  /// Gaussian-blurred grayscale image.
  blurred,

  /// Canny edge detection output.
  canny,

  /// Morphologically closed edge map (after closing gaps).
  morphClosed,

  /// The contours drawn on a blank image.
  contours,
}
