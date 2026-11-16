import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum RemoteOcrModeEnum {
  always('always'),
  workflowOnly('workflow_only');

  const RemoteOcrModeEnum(this.value);

  final String value;
}
