import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum ArchiveFileGenerationEnum {
  auto('auto'),
  always('always'),
  never('never');

  const ArchiveFileGenerationEnum(this.value);

  final String value;
}
