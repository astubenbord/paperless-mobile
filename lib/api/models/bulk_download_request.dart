import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:paperless_mobile/api/models/compression_enum.dart';
import 'package:paperless_mobile/api/models/content_enum.dart';

part 'bulk_download_request.freezed.dart';
part 'bulk_download_request.g.dart';

@Freezed(toJson: true, fromJson: false)
abstract class BulkDownloadRequest with _$BulkDownloadRequest {
  factory BulkDownloadRequest({
    List<int>? documents,
    @Default(false) bool? all,
    Map<String, Object>? filters,
    List<int>? excludedDocuments,
    @Default(ContentEnum.archive) ContentEnum? content,
    @Default(CompressionEnum.none) CompressionEnum? compression,
    @Default(false) bool? followFormatting,
  }) = _BulkDownloadRequest;
}
