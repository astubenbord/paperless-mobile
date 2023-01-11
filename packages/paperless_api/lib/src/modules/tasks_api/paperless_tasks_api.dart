import 'package:paperless_api/src/models/task/task.dart';

abstract class PaperlessTasksApi {
  Future<Task?> find({int? id, String? taskId});
  Future<Iterable<Task>> findAll([Iterable<int>? ids]);
  Stream<Task> listenForTaskChanges(String taskId);
  Future<Task> acknowledgeTask(Task task);
  Future<Iterable<Task>> acknowledgeTasks(Iterable<Task> tasks);
}
