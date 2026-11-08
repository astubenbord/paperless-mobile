import 'package:json_annotation/json_annotation.dart';
import 'package:paperless_mobile/features/notifications/models/notification_actions.dart';
import 'package:paperless_mobile/features/notifications/models/notification_payloads/notification_tap/notification_tap_response_payload.dart';
import 'package:paperless_mobile/features/notifications/models/notification_payloads/notification_tap/open_directory_notification_response_payload.dart';

class NotificationTapResponsePayloadConverter
    implements
        JsonConverter<NotificationTapResponsePayload, Map<String, dynamic>> {
  const NotificationTapResponsePayloadConverter();
  @override
  NotificationTapResponsePayload fromJson(Map<String, dynamic> json) {
    final type = NotificationResponseOpenAction.values.byName(json['type']);
    switch (type) {
      case NotificationResponseOpenAction.openDirectory:
        return OpenDirectoryNotificationResponsePayload.fromJson(json);
    }
  }

  @override
  Map<String, dynamic> toJson(NotificationTapResponsePayload object) {
    return object.toJson();
  }
}
