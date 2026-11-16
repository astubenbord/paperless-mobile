import 'package:freezed_annotation/freezed_annotation.dart';

part 'document_barcode.freezed.dart';
part 'document_barcode.g.dart';

@Freezed(toJson: true, fromJson: true)
abstract class DocumentBarcode with _$DocumentBarcode {
  factory DocumentBarcode({
    required int page,
    required String value,
    required String format,
  }) = _DocumentBarcode;

  factory DocumentBarcode.fromJson(Map<String, dynamic> json) =>
      _$DocumentBarcodeFromJson(json);
}
