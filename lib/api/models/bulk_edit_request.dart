import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:paperless_mobile/api/models/method_enum.dart';

part 'bulk_edit_request.freezed.dart';
part 'bulk_edit_request.g.dart';

@Freezed(toJson: true, fromJson: false)
abstract class BulkEditRequest with _$BulkEditRequest {
  factory BulkEditRequest({
    @Default([]) List<int> documents,
    @Default(false) bool? all,
    Map<String, Object>? filters,
    List<int>? excludedDocuments,
    required MethodEnum method,
    @Default({}) Map<String, Object>? parameters,
    @Default(false) bool? fromWebui,
  }) = _BulkEditRequest;
}
