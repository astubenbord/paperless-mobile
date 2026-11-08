import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:paperless_mobile/api/models/archive_file_generation_enum.dart';
import 'package:paperless_mobile/api/models/color_conversion_strategy_enum.dart';
import 'package:paperless_mobile/api/models/llm_backend_enum.dart';
import 'package:paperless_mobile/api/models/llm_embedding_backend_enum.dart';
import 'package:paperless_mobile/api/models/mode_enum.dart';
import 'package:paperless_mobile/api/models/output_type_enum.dart';
import 'package:paperless_mobile/api/models/remote_ocr_engine_enum.dart';
import 'package:paperless_mobile/api/models/remote_ocr_mode_enum.dart';
import 'package:paperless_mobile/api/models/skip_archive_file_enum.dart';
import 'package:paperless_mobile/api/models/unpaper_clean_enum.dart';

part 'application_configuration.freezed.dart';
part 'application_configuration.g.dart';

@Freezed(toJson: false, fromJson: true)
abstract class ApplicationConfiguration with _$ApplicationConfiguration {
  factory ApplicationConfiguration({
    required int id,
    required Object? userArgs,
    required Object? barcodeTagMapping,
    OutputTypeEnum? outputType,
    // minimum: 1
    // maximum: 2147483647
    int? pages,
    String? language,
    ModeEnum? mode,
    SkipArchiveFileEnum? skipArchiveFile,
    // minimum: 1
    // maximum: 2147483647
    int? imageDpi,
    UnpaperCleanEnum? unpaperClean,
    bool? deskew,
    bool? rotatePages,
    // minimum: 0.0
    double? rotatePagesThreshold,
    // minimum: 0.0
    double? maxImagePixels,
    ColorConversionStrategyEnum? colorConversionStrategy,
    String? appTitle,
    String? appLogo,
    bool? barcodesEnabled,
    bool? barcodeEnableTiffSupport,
    String? barcodeString,
    bool? barcodeRetainSplitPages,
    bool? barcodeEnableAsn,
    String? barcodeAsnPrefix,
    // minimum: 1.0
    double? barcodeUpscale,
    // minimum: 1
    // maximum: 2147483647
    int? barcodeDpi,
    // minimum: 1
    // maximum: 2147483647
    int? barcodeMaxPages,
    bool? barcodeEnableTag,
    bool? aiEnabled,
    ArchiveFileGenerationEnum? archiveFileGeneration,
    bool? barcodeStoreValues,
    bool? barcodeTagSplit,
    @Default([]) List<String> externallyConfiguredVariables,
    String? llmApiKey,
    LlmBackendEnum? llmBackend,
    int? llmContextSize,
    String? llmEmbeddingApiKey,
    LlmEmbeddingBackendEnum? llmEmbeddingBackend,
    int? llmEmbeddingChunkSize,
    String? llmEmbeddingEndpoint,
    String? llmEmbeddingModel,
    String? llmEndpoint,
    String? llmModel,
    String? llmOutputLanguage,
    int? llmRequestTimeout,
    String? remoteOcrApiKey,
    String? remoteOcrEndpoint,
    RemoteOcrEngineEnum? remoteOcrEngine,
    RemoteOcrModeEnum? remoteOcrMode,
  }) = _ApplicationConfiguration;

  factory ApplicationConfiguration.fromJson(Map<String, dynamic> json) =>
      _$ApplicationConfigurationFromJson(json);
}
