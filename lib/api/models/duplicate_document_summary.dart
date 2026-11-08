import 'package:freezed_annotation/freezed_annotation.dart';

part 'duplicate_document_summary.freezed.dart';
part 'duplicate_document_summary.g.dart';

@Freezed(toJson: true, fromJson: true)
abstract class DuplicateDocumentSummary with _$DuplicateDocumentSummary {
  factory DuplicateDocumentSummary({
    required int id,
    required String title,
    required DateTime? deletedAt,
  }) = _DuplicateDocumentSummary;

  factory DuplicateDocumentSummary.fromJson(Map<String, dynamic> json) =>
      _$DuplicateDocumentSummaryFromJson(json);
}
