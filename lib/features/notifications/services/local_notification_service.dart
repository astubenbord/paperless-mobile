import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:open_file/open_file.dart';
import 'package:paperless_mobile/api/models/status_enum.dart';
import 'package:paperless_mobile/api/models/tasks_view.dart';
import 'package:paperless_mobile/features/notifications/converters/notification_tap_response_payload.dart';
import 'package:paperless_mobile/features/notifications/models/notification_actions.dart';
import 'package:paperless_mobile/features/notifications/models/notification_channels.dart';
import 'package:paperless_mobile/features/notifications/models/notification_payloads/notification_action/create_document_success_payload.dart';
import 'package:paperless_mobile/features/notifications/models/notification_payloads/notification_tap/open_directory_notification_response_payload.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class LocalNotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  LocalNotificationService();

  final Map<String, List<int>> _pendingNotifications = {};

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('paperless_logo_green');
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestSoundPermission: false,
          requestBadgePermission: false,
          requestAlertPermission: false,
        );
    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );
    await _plugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          onDidReceiveBackgroundNotificationResponse,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> notifyFileDownload({required String filePath}) async {
    await _plugin.show(
      filePath.hashCode,
      filePath,
      "File download complete.",
      NotificationDetails(
        android: AndroidNotificationDetails(
          "${NotificationChannel.fileDownload.id}_${filePath.hashCode}",
          NotificationChannel.fileDownload.name,
          importance: Importance.max,
          priority: Priority.high,
          showProgress: false,
          when: DateTime.now().millisecondsSinceEpoch,
          category: AndroidNotificationCategory.status,
          icon: 'file_download_done',
        ),
      ),
      payload: jsonEncode(
        OpenDirectoryNotificationResponsePayload(filePath: filePath).toJson(),
      ),
    );
  }

  Future<void> notifyDocumentDownload({
    required int documentId,
    required String filename,
    required String filePath,
    required bool finished,
    required String locale,
    required String userId,
    double? progress,
  }) async {
    final tr = await S.delegate.load(Locale(locale));

    await _plugin.show(
      documentId,
      filename,
      finished
          ? tr.notificationDownloadComplete
          : tr.notificationDownloadingDocument,
      NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationChannel.documentDownload.id,
          NotificationChannel.documentDownload.name,
          progress: ((progress ?? 0) * 100).toInt(),
          maxProgress: 100,
          indeterminate: progress == null && !finished,
          ongoing: !finished,
          importance: Importance.max,
          priority: Priority.high,
          showProgress: !finished,
          when: DateTime.now().millisecondsSinceEpoch,
          category: AndroidNotificationCategory.progress,
          icon: finished ? 'file_download_done' : 'downloading',
          channelDescription: 'Notifications for document download status',
        ),
      ),
      payload: jsonEncode(
        OpenDirectoryNotificationResponsePayload(filePath: filePath).toJson(),
      ),
    );
    _addNotification(userId, documentId);
  }

  void _addNotification(String userId, int notificationId) {
    _pendingNotifications.update(
      userId,
      (notifications) => [...notifications, notificationId],
      ifAbsent: () => [notificationId],
    );
  }

  Future<void> notifyFileSaved({
    required String filename,
    required String filePath,
    required bool finished,
    required String locale,
  }) async {
    final tr = await S.delegate.load(Locale(locale));

    await _plugin.show(
      filePath.hashCode,
      filename,
      finished
          ? tr.notificationDownloadComplete
          : tr.notificationDownloadingDocument,
      NotificationDetails(
        android: AndroidNotificationDetails(
          "${NotificationChannel.documentDownload.id}_$filename",
          NotificationChannel.documentDownload.name,
          ongoing: !finished,
          indeterminate: true,
          importance: Importance.max,
          priority: Priority.high,
          showProgress: !finished,
          when: DateTime.now().millisecondsSinceEpoch,
          category: AndroidNotificationCategory.progress,
          icon: finished ? 'file_download_done' : 'downloading',
        ),
        iOS: DarwinNotificationDetails(
          attachments: [DarwinNotificationAttachment(filePath)],
        ),
      ),
      payload: jsonEncode(
        OpenDirectoryNotificationResponsePayload(filePath: filePath).toJson(),
      ),
    );
  }

  //TODO: INTL
  Future<void> notifyTaskChanged(
    TasksView task, {
    required String userId,
  }) async {
    log("[LocalNotificationService] notifyTaskChanged: ${task.toString()}");
    int id = task.id + 1000;
    final status = task.status;
    late String title;
    late String? body;
    late int timestampMillis;
    bool showProgress =
        status == StatusEnum.started || status == StatusEnum.pending;
    dynamic payload;
    switch (status) {
      case StatusEnum.started:
        title = 'Document received';
        body = task.taskFileName;
        timestampMillis = task.dateCreated?.millisecondsSinceEpoch ?? 0;
        break;
      case StatusEnum.pending:
        title = "Processing document...";
        body = task.taskFileName;
        timestampMillis = task.dateCreated?.millisecondsSinceEpoch ?? 0;
        break;
      case StatusEnum.failure:
        title = "Failed to process document";
        body = task.result ?? 'Rejected by the server.';
        timestampMillis = task.dateCreated?.millisecondsSinceEpoch ?? 0;
        break;
      case StatusEnum.success:
        title = "Document successfully created";
        body = task.taskFileName;
        timestampMillis = task.dateDone?.millisecondsSinceEpoch ?? 0;
        payload = CreateDocumentSuccessPayload(
          int.tryParse(task.relatedDocument ?? '') ?? -1,
        );
        break;
      default:
        break;
    }
    await _plugin.show(
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
          indeterminate: true,
          actions: status == StatusEnum.success
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
        //TODO: Add darwin support
      ),
      payload: jsonEncode(payload),
    );
    _addNotification(userId, id);
  }

  Future<void> cancelUserNotifications(String userId) async {
    await Future.wait([
      for (var id in _pendingNotifications[userId] ?? []) _plugin.cancel(id),
    ]);
  }

  void onDidReceiveNotificationResponse(NotificationResponse response) {
    debugPrint(
      "Received Notification ${response.id}: Action is ${response.actionId}): ${response.payload}",
    );
    switch (response.notificationResponseType) {
      case NotificationResponseType.selectedNotification:
        if (response.payload != null) {
          final payload = const NotificationTapResponsePayloadConverter()
              .fromJson(jsonDecode(response.payload!));
          _handleResponseTapAction(payload.type, response);
        }

        break;
      case NotificationResponseType.selectedNotificationAction:
        final action = NotificationResponseButtonAction.values.byName(
          response.actionId!,
        );
        _handleResponseButtonAction(action, response);
        break;
    }
  }

  void _handleResponseButtonAction(
    NotificationResponseButtonAction action,
    NotificationResponse response,
  ) {
    switch (action) {
      case NotificationResponseButtonAction.openCreatedDocument:
        final payload = CreateDocumentSuccessPayload.fromJson(
          jsonDecode(response.payload!),
        );
        log("Navigate to document ${payload.documentId}");
        break;
      case NotificationResponseButtonAction.acknowledgeCreatedDocument:
        final payload = CreateDocumentSuccessPayload.fromJson(
          jsonDecode(response.payload!),
        );
        log("Acknowledge document ${payload.documentId}");
        break;
    }
  }

  void _handleResponseTapAction(
    NotificationResponseOpenAction type,
    NotificationResponse response,
  ) {
    switch (type) {
      case NotificationResponseOpenAction.openDirectory:
        final payload = OpenDirectoryNotificationResponsePayload.fromJson(
          jsonDecode(response.payload!),
        );
        OpenFile.open(payload.filePath);
        break;
    }
  }
}

@protected
void onDidReceiveBackgroundNotificationResponse(NotificationResponse response) {
  //TODO: When periodic background inbox check is implemented, notification tap is handled here
  debugPrint(response.toString());
}
