import 'dart:convert';
import 'dart:developer';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/features/notifications/services/models/notification_payloads/open_created_document_notification_payload.dart';
import 'package:paperless_mobile/features/notifications/services/notification_actions.dart';
import 'package:paperless_mobile/features/notifications/services/notification_channels.dart';

class LocalNotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  LocalNotificationService();

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_stat_paperless_logo_green');
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
      onDidReceiveLocalNotification: onDidReceiveLocalNotification,
    );
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    await _plugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );
  }

  //TODO: INTL
  Future<void> notifyTaskChanged(Task task) {
    log("[LocalNotificationService] notifyTaskChanged: ${task.toString()}");
    int id = task.id;
    final status = task.status;
    late String title;
    late String? body;
    late int timestampMillis;
    bool showProgress =
        status == TaskStatus.started || status == TaskStatus.pending;
    int progress = 0;
    dynamic payload;
    switch (status) {
      case TaskStatus.started:
        title = "Document received";
        body = task.taskFileName;
        timestampMillis = task.dateCreated.millisecondsSinceEpoch;
        progress = 10;
        break;
      case TaskStatus.pending:
        title = "Processing document...";
        body = task.taskFileName;
        timestampMillis = task.dateCreated.millisecondsSinceEpoch;
        progress = 70;
        break;
      case TaskStatus.failure:
        title = "Failed to process document";
        body = "Document ${task.taskFileName} was rejected by the server.";
        timestampMillis = task.dateCreated.millisecondsSinceEpoch;
        break;
      case TaskStatus.success:
        title = "Document successfully created";
        body = task.taskFileName;
        timestampMillis = task.dateDone!.millisecondsSinceEpoch;
        payload = CreateDocumentSuccessNotificationResponsePayload(
          task.relatedDocument!,
        );
        break;
      default:
        break;
    }
    return _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          '${NotificationChannel.task.id}_${task.id}',
          NotificationChannel.task.name,
          category: AndroidNotificationCategory.status,
          ongoing: showProgress,
          showProgress: showProgress,
          maxProgress: 100,
          when: timestampMillis,
          progress: progress,
          actions: status == TaskStatus.success
              ? [
                  //TODO: Implement once moved to new routing
                  // AndroidNotificationAction(
                  //   NotificationResponseAction.openCreatedDocument.name,
                  //   "Open",
                  //   showsUserInterface: true,
                  // ),
                  // AndroidNotificationAction(
                  //   NotificationResponseAction.acknowledgeCreatedDocument.name,
                  //   "Acknowledge",
                  // ),
                ]
              : [],
        ),
      ),
      payload: jsonEncode(payload),
    );
  }

  void onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) {}

  void onDidReceiveNotificationResponse(NotificationResponse response) {
    log("Received Notification: ${response.payload}");
    if (response.notificationResponseType ==
        NotificationResponseType.selectedNotificationAction) {
      final action =
          NotificationResponseAction.values.byName(response.actionId!);
      _handleResponseAction(action, response);
    }
    // Non-actionable notification pressed, ignoring...
  }

  void _handleResponseAction(
    NotificationResponseAction action,
    NotificationResponse response,
  ) {
    switch (action) {
      case NotificationResponseAction.openCreatedDocument:
        final payload =
            CreateDocumentSuccessNotificationResponsePayload.fromJson(
          jsonDecode(response.payload!),
        );
        log("Navigate to document ${payload.documentId}");
        break;
      case NotificationResponseAction.acknowledgeCreatedDocument:
        final payload =
            CreateDocumentSuccessNotificationResponsePayload.fromJson(
          jsonDecode(response.payload!),
        );
        log("Acknowledge document ${payload.documentId}");
        break;
    }
  }
}
