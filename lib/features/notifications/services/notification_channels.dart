enum NotificationChannel {
  task("task_channel", "Paperless Tasks");

  final String id;
  final String name;

  const NotificationChannel(this.id, this.name);
}
