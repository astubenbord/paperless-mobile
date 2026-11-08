import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum LlmEmbeddingBackendEnum {
  openaiLike('openai-like'),
  huggingface('huggingface'),
  ollama('ollama');

  const LlmEmbeddingBackendEnum(this.value);

  final String value;
}
