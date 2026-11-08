// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:paperless_mobile/api/models/data_type_enum.dart';

part 'custom_field.freezed.dart';
part 'custom_field.g.dart';

@Freezed(toJson: false, fromJson: true)
abstract class CustomField with _$CustomField {
  factory CustomField({
    required int id,
    required String name,
    @JsonKey(fromJson: dataTypeEnumFromJson) required DataTypeEnum dataType,

    /// Extra data for the custom field, such as select options
    Object? extraData,
    @Default(0) int documentCount,
  }) = _CustomField;

  factory CustomField.fromJson(Map<String, dynamic> json) =>
      _$CustomFieldFromJson(json);
}
