import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_mobile/api/models/status_enum.dart';
import 'package:paperless_mobile/api/models/tasks_view.dart';
import 'package:paperless_mobile/features/notifications/models/notification_channels.dart';
import 'package:paperless_mobile/features/notifications/services/local_notification_service.dart';

class MockFlutterLocalNotificationsPlugin extends Fake
    implements FlutterLocalNotificationsPlugin {
  final List<NotificationDetails?> shownDetails = [];
  final List<int> shownIds = [];

  @override
  Future<void> show(
    int id,
    String? title,
    String? body,
    NotificationDetails? notificationDetails, {
    String? payload,
  }) async {
    shownIds.add(id);
    shownDetails.add(notificationDetails);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFlutterLocalNotificationsPlugin mockPlugin;
  late LocalNotificationService service;

  setUp(() {
    mockPlugin = MockFlutterLocalNotificationsPlugin();
    service = LocalNotificationService(plugin: mockPlugin);
  });

  group('LocalNotificationService - Notification Channels', () {
    test(
      'notifyTaskChanged uses static NotificationChannel.task.id across multiple tasks (#422)',
      () async {
        final task1 = TasksView(
          id: 101,
          taskId: 'task-uuid-1',
          status: StatusEnum.pending,
          taskFileName: 'scan_1.pdf',
        );
        final task2 = TasksView(
          id: 102,
          taskId: 'task-uuid-2',
          status: StatusEnum.success,
          taskFileName: 'scan_2.pdf',
        );

        await service.notifyTaskChanged(task1, userId: 'user-1');
        await service.notifyTaskChanged(task2, userId: 'user-1');

        expect(mockPlugin.shownDetails.length, 2);

        final details1 = mockPlugin.shownDetails[0]?.android;
        final details2 = mockPlugin.shownDetails[1]?.android;

        expect(details1?.channelId, equals(NotificationChannel.task.id));
        expect(details2?.channelId, equals(NotificationChannel.task.id));
        expect(details1?.channelName, equals(NotificationChannel.task.name));
        expect(details2?.channelName, equals(NotificationChannel.task.name));

        // Ensure notification IDs differ per task, but channel ID remains static
        expect(mockPlugin.shownIds[0], isNot(equals(mockPlugin.shownIds[1])));
        expect(details1?.channelId, equals(details2?.channelId));
      },
    );

    test(
      'notifyFileDownload uses static NotificationChannel.fileDownload.id',
      () async {
        await service.notifyFileDownload(filePath: '/storage/path/doc_a.pdf');
        await service.notifyFileDownload(filePath: '/storage/path/doc_b.pdf');

        expect(mockPlugin.shownDetails.length, 2);

        final details1 = mockPlugin.shownDetails[0]?.android;
        final details2 = mockPlugin.shownDetails[1]?.android;

        expect(
          details1?.channelId,
          equals(NotificationChannel.fileDownload.id),
        );
        expect(
          details2?.channelId,
          equals(NotificationChannel.fileDownload.id),
        );
        expect(
          details1?.channelName,
          equals(NotificationChannel.fileDownload.name),
        );
        expect(
          details2?.channelName,
          equals(NotificationChannel.fileDownload.name),
        );
      },
    );
  });
}
