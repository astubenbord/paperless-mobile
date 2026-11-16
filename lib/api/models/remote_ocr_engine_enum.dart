import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum RemoteOcrEngineEnum {
  azureAi('azureai');

  const RemoteOcrEngineEnum(this.value);

  final String value;
}
