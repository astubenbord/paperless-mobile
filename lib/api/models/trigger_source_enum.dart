import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum TriggerSourceEnum {
  scheduled('scheduled'),
  webUi('web_ui'),
  apiUpload('api_upload'),
  folderConsume('folder_consume'),
  emailConsume('email_consume'),
  system('system'),
  manual('manual');

  const TriggerSourceEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
