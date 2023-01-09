import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum TaskStatus {
  started("STARTED"),
  pending("PENDING"),
  failure("FAILURE"),
  success("SUCCESS");

  final String value;

  const TaskStatus(this.value);
}
