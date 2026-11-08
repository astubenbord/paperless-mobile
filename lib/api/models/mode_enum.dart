import 'package:json_annotation/json_annotation.dart';

@JsonEnum(fieldRename: FieldRename.snake)
enum ModeEnum {
  auto,
  off,
  skip,
  redo,
  force,
  skipNoarchive;

  @override
  String toString() => name;
}
