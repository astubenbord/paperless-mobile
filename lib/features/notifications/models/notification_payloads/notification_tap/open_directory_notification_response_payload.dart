import 'package:json_annotation/json_annotation.dart';
import 'package:paperless_mobile/features/notifications/models/notification_actions.dart';
import 'package:paperless_mobile/features/notifications/models/notification_payloads/notification_tap/notification_tap_response_payload.dart';

part 'open_directory_notification_response_payload.g.dart';

@JsonSerializable()
class OpenDirectoryNotificationResponsePayload
    extends NotificationTapResponsePayload {
  final String filePath;
  OpenDirectoryNotificationResponsePayload({
    required this.filePath,
    super.type = NotificationResponseOpenAction.openDirectory,
  });

  factory OpenDirectoryNotificationResponsePayload.fromJson(
    Map<String, dynamic> json,
  ) => _$OpenDirectoryNotificationResponsePayloadFromJson(json);
  @override
  Map<String, dynamic> toJson() =>
      _$OpenDirectoryNotificationResponsePayloadToJson(this);
}
