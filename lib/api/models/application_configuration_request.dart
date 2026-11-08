import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:paperless_mobile/api/models/models.dart';

part 'application_configuration_request.freezed.dart';
part 'application_configuration_request.g.dart';

@Freezed(toJson: true, fromJson: false)
abstract class ApplicationConfigurationRequest
    with _$ApplicationConfigurationRequest {
  factory ApplicationConfigurationRequest({
    Object? userArgs,
    Object? barcodeTagMapping,
    OutputTypeEnum? outputType,
    int? pages,
    String? language,
    ModeEnum? mode,
    SkipArchiveFileEnum? skipArchiveFile,
    int? imageDpi,
    UnpaperCleanEnum? unpaperClean,
    bool? deskew,
    bool? rotatePages,
    double? rotatePagesThreshold,
    double? maxImagePixels,
    ColorConversionStrategyEnum? colorConversionStrategy,
    String? appTitle,
    // @JsonKey(includeToJson: false) MultipartFile? appLogo,
    bool? barcodesEnabled,
    bool? barcodeEnableTiffSupport,
    String? barcodeString,
    bool? barcodeRetainSplitPages,
    bool? barcodeEnableAsn,
    String? barcodeAsnPrefix,
    double? barcodeUpscale,
    int? barcodeDpi,
    int? barcodeMaxPages,
    bool? barcodeEnableTag,
    bool? aiEnabled,
    ArchiveFileGenerationEnum? archiveFileGeneration,
    bool? barcodeStoreValues,
    bool? barcodeTagSplit,
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
  }) = _ApplicationConfigurationRequest;
}
