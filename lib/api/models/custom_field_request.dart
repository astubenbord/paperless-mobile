// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:paperless_mobile/api/models/data_type_enum.dart';

part 'custom_field_request.freezed.dart';
part 'custom_field_request.g.dart';

@Freezed(toJson: true, fromJson: false)
abstract class CustomFieldRequest with _$CustomFieldRequest {
  factory CustomFieldRequest({
    required String name,
    @JsonKey(toJson: dataTypeEnumToJson) required DataTypeEnum dataType,

    /// Extra data for the custom field, such as select options
    Object? extraData,
  }) = _CustomFieldRequest;
}
