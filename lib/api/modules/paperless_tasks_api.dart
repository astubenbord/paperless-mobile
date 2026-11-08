import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:paperless_mobile/api/models/models.dart';
import 'package:paperless_mobile/api/extensions/extensions.dart';
import 'package:paperless_mobile/api/utils/request_utils.dart';

abstract class PaperlessTasksApi {
  Future<TasksView?> find(int id);
  Future<Iterable<TasksView>> findAll([TaskFilterOptions options]);
  Stream<TasksView> listenForTaskChanges(String taskId);
  Future<void> acknowledgeTasks(Iterable<int> tasks);
}

class PaperlessTasksApiImpl implements PaperlessTasksApi {
  final Dio _client;

  PaperlessTasksApiImpl(this._client);

  @override
  Future<TasksView?> find(int id) async {
    return getSingleResult(
      '/api/tasks/$id/',
      TasksView.fromJson,
      ErrorCode.loadTasksError,
      client: _client,
    );
  }

  @override
  Future<Iterable<TasksView>> findAll([
    TaskFilterOptions options = const TaskFilterOptions(),
  ]) async {
    return getCollection(
      '/api/tasks/',
      TasksView.fromJson,
      ErrorCode.loadTasksError,
      client: _client,
      queryParams: options.toJson(),
    );
  }

  @override
  Stream<TasksView> listenForTaskChanges(String taskId) async* {
    bool isCompleted = false;
    while (!isCompleted) {
      final tasks = await findAll(TaskFilterOptions(taskId: taskId));
      if (tasks.isEmpty) {
        await Future.delayed(const Duration(seconds: 2));
        continue;
      }
      final task = tasks.first;
      log("Found new task: ${task.taskId}, ${task.id}, ${task.status}");
      yield task;
      if (task.status == StatusEnum.success ||
          task.status == StatusEnum.failure ||
          task.status == StatusEnum.revoked) {
        isCompleted = true;
      }
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  @override
  Future<void> acknowledgeTasks(Iterable<int> tasks) async {
    try {
      final response = await _client.post(
        "/api/tasks/acknowledge/",
        data: {'tasks': tasks.toList()},
        options: Options(validateStatus: (status) => status == 200),
      );
      final acknowledgedTaskCount = AcknowledgeTasks.fromJson(
        response.data,
      ).result;
      if (acknowledgedTaskCount != tasks.length) {
        throw const PaperlessApiException(ErrorCode.acknowledgeTasksError);
      }
    } on DioException catch (exception) {
      throw exception.unravel(
        orElse: const PaperlessApiException(ErrorCode.acknowledgeTasksError),
      );
    }
  }
}
