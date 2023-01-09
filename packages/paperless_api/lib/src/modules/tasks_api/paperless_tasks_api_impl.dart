import 'package:dio/dio.dart';
import 'package:paperless_api/src/models/task/task.dart';
import 'package:paperless_api/src/models/task/task_status.dart';

import 'paperless_tasks_api.dart';

class PaperlessTasksApiImpl implements PaperlessTasksApi {
  final Dio client;

  const PaperlessTasksApiImpl(this.client);

  @override
  Future<Task?> find({int? id, String? taskId}) async {
    assert(id != null || taskId != null);
    String url = "/api/tasks/";
    if (taskId != null) {
      url += "?task_id=$taskId";
    } else {
      url += "$id/";
    }

    final response = await client.get(url);
    if (response.statusCode == 200) {
      return Task.fromJson(response.data);
    }
    return null;
  }

  @override
  Future<Iterable<Task>> findAll([Iterable<int>? ids]) async {
    final response = await client.get("/api/tasks/");
    if (response.statusCode == 200) {
      return (response.data as List).map((e) => Task.fromJson(e));
    }
    return [];
  }

  @override
  Stream<Task> listenForTaskChanges(String taskId) async* {
    bool isSuccess = false;
    while (!isSuccess) {
      final task = await find(taskId: taskId);
      if (task == null) {
        throw Exception("Task with taskId $taskId does not exist.");
      }
      yield task;
      if (task.status == TaskStatus.success) {
        isSuccess = true;
      }
      await Future.delayed(const Duration(seconds: 1));
    }
  }
}
