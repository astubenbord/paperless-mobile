import 'package:json_annotation/json_annotation.dart';

enum NotificationResponseButtonAction {
  openCreatedDocument,
  acknowledgeCreatedDocument,
}

@JsonEnum()
enum NotificationResponseOpenAction { openDirectory }
