import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum WorkflowActionTypeEnum {
  assignment(1),
  removal(2),
  email(3),
  webhook(4),
  passwordRemoval(5),
  moveToTrash(6),
  remoteOcr(7),
  applyAiSuggestions(8);

  const WorkflowActionTypeEnum(this.value);

  final int value;

  @override
  String toString() => name;
}
