import 'package:camera/camera.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:paperless_mobile/features/scanner/models/edge_detection_config.dart';
import 'package:paperless_mobile/features/scanner/models/auto_capture_config.dart';

part 'scanner_parameters.g.dart';

@CopyWith()
@JsonSerializable()
class ScannerParameters {
  const ScannerParameters({
    this.resizeThreshold = 320,
    this.borderSize = 10,
    this.medianBlurKernel = 7,
    this.approxEpsilonFactor = 0.018,
    this.morphologyKernel = 3,
    this.dilateKernel = 2,
    this.minAreaFactor = 0.03,
    this.stableDurationMs = 1000,
    this.preStableDelayMs = 1000,
    this.distanceThreshold = 50.0,
    this.minConsecutiveSimilarFrames = 3,
    this.resolutionPreset = 'max',
  });

  // EdgeDetectionConfig defaults (fast preset)
  final int resizeThreshold;
  final int borderSize;
  final int medianBlurKernel;
  final double approxEpsilonFactor;
  final int morphologyKernel;
  final int dilateKernel;
  final double minAreaFactor;

  // AutoCaptureConfig defaults
  final int stableDurationMs;
  final int preStableDelayMs;
  final double distanceThreshold;
  final int minConsecutiveSimilarFrames;

  // Camera resolution
  final String resolutionPreset;

  ResolutionPreset get resolutionPresetValue {
    return ResolutionPreset.values.firstWhere(
      (e) => e.name == resolutionPreset,
      orElse: () => ResolutionPreset.max,
    );
  }

  EdgeDetectionConfig toEdgeDetectionConfig() {
    return EdgeDetectionConfig(
      resizeThreshold: resizeThreshold,
      borderSize: borderSize,
      medianBlurKernel: medianBlurKernel,
      approxEpsilonFactor: approxEpsilonFactor,
      morphologyKernel: morphologyKernel,
      dilateKernel: dilateKernel,
      minAreaFactor: minAreaFactor,
    );
  }

  AutoCaptureConfig toAutoCaptureConfig({bool enabled = true}) {
    return AutoCaptureConfig(
      enabled: enabled,
      stableDuration: Duration(milliseconds: stableDurationMs),
      preStableDelay: Duration(milliseconds: preStableDelayMs),
      distanceThreshold: distanceThreshold,
      minConsecutiveSimilarFrames: minConsecutiveSimilarFrames,
    );
  }

  Map<String, dynamic> toJson() => _$ScannerParametersToJson(this);
  factory ScannerParameters.fromJson(Map<String, dynamic> json) =>
      _$ScannerParametersFromJson(json);
}
