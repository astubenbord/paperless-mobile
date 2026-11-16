import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum LlmBackendEnum {
  openaiLike('openai-like'),
  ollama('ollama');

  const LlmBackendEnum(this.value);

  final String value;
}
