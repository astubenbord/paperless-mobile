import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:paperless_mobile/api/models/object_type_enum.dart';
import 'package:paperless_mobile/api/models/operation_enum.dart';

part 'bulk_edit_objects_request.freezed.dart';
part 'bulk_edit_objects_request.g.dart';

@Freezed(toJson: true, fromJson: false)
abstract class BulkEditObjectsRequest with _$BulkEditObjectsRequest {
  factory BulkEditObjectsRequest({
    List<int>? objects,
    @Default(false) bool? all,
    Map<String, Object>? filters,
    required ObjectTypeEnum objectType,
    required OperationEnum operation,
    int? owner,
    Map<String, Object>? permissions,
    @Default(false) bool? merge,
  }) = _BulkEditObjectsRequest;
}
