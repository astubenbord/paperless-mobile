import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:paperless_mobile/api/models/status_enum.dart';
import 'package:paperless_mobile/api/models/task_name_enum.dart';
import 'package:paperless_mobile/api/models/task_type_enum.dart';
import 'package:paperless_mobile/api/models/trigger_source_enum.dart';
import 'package:paperless_mobile/api/models/tasks_view_type_enum.dart';

part 'tasks_view.freezed.dart';
part 'tasks_view.g.dart';

@Freezed(toJson: true, fromJson: true)
abstract class TasksView with _$TasksView {
  factory TasksView({
    required int id,

    /// Celery ID for the Task that was run
    required String taskId,
    TaskNameEnum? taskName,
    TaskTypeEnum? taskType,

    /// Name of the file which the Task was run for
    String? taskFileName,
    Map<String, dynamic>? inputData,

    /// Datetime field when the task result was created in UTC
    DateTime? dateCreated,

    /// Datetime field when the task was completed in UTC
    DateTime? dateDone,

    /// The type of task that was run  * `auto_task` - Auto Task * `scheduled_task` - Scheduled Task * `manual_task` - Manual Task
    TasksViewTypeEnum? type,
    TriggerSourceEnum? triggerSource,

    /// Current task status: pending, started, success, failure, or revoked.
    StatusEnum? status,

    /// The data returned by the task
    String? result,
    Object? resultData,
    String? statusDisplay,
    String? taskTypeDisplay,
    String? triggerSourceDisplay,
    DateTime? dateStarted,
    double? durationSeconds,
    double? waitTimeSeconds,
    List<int>? relatedDocumentIds,

    /// If the task is acknowledged via the frontend or API
    bool? acknowledged,
    String? relatedDocument,
    int? owner,
  }) = _TasksView;

  factory TasksView.fromJson(Map<String, dynamic> json) =>
      _$TasksViewFromJson(_normalizeTasksViewJson(json));
}

Map<String, dynamic> _normalizeTasksViewJson(Map<String, dynamic> json) {
  final normalized = Map<String, dynamic>.from(json);
  final inputData = normalized['input_data'];

  if (!normalized.containsKey('task_file_name') && inputData is Map) {
    normalized['task_file_name'] = inputData['filename'];
  }
  if (!normalized.containsKey('result') &&
      normalized.containsKey('result_data')) {
    normalized['result'] = _taskResultFromJson(normalized['result_data']);
  }
  if (!normalized.containsKey('related_document')) {
    final relatedDocumentIds = normalized['related_document_ids'];
    if (relatedDocumentIds is List && relatedDocumentIds.isNotEmpty) {
      normalized['related_document'] = relatedDocumentIds.first.toString();
    }
  }
  if (normalized['status'] is String) {
    normalized['status'] = (normalized['status'] as String).toUpperCase();
  }

  return normalized;
}

String? _taskResultFromJson(Object? value) {
  if (value == null) return null;
  if (value is String) return value;
  if (value is Map) {
    final error = value['error_message'] ?? value['reason'];
    if (error is String) return error;
    final documentId = value['document_id'];
    if (documentId != null) {
      return 'Success. New document id $documentId created';
    }
    final duplicateId = value['duplicate_of'];
    if (duplicateId != null) {
      return 'Not consuming: It is a duplicate of document #$duplicateId';
    }
  }
  return jsonEncode(value);
}
