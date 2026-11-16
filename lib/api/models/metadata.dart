import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:paperless_mobile/api/models/document_barcode.dart';

part 'metadata.freezed.dart';
part 'metadata.g.dart';

@Freezed(toJson: true, fromJson: true)
abstract class Metadata with _$Metadata {
  factory Metadata({
    String? originalChecksum,
    int? originalSize,
    String? originalMimeType,
    String? mediaFilename,
    bool? hasArchiveVersion,
    List<Object>? originalMetadata,
    String? archiveChecksum,
    String? archiveMediaFilename,
    String? originalFilename,
    int? archiveSize,
    List<Object>? archiveMetadata,
    String? lang,
    @Default([]) List<DocumentBarcode> barcodes,
  }) = _Metadata;

  factory Metadata.fromJson(Map<String, dynamic> json) =>
      _$MetadataFromJson(json);
}
