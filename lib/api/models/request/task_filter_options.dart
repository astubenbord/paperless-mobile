import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:paperless_mobile/api/models/status_enum.dart';
import 'package:paperless_mobile/api/models/task_name_enum.dart';
import 'package:paperless_mobile/api/models/task_type_enum.dart';
import 'package:paperless_mobile/api/models/trigger_source_enum.dart';
import 'package:paperless_mobile/api/models/tasks_view_type_enum.dart';

part 'task_filter_options.g.dart';

@CopyWith()
@JsonSerializable(createFactory: false, includeIfNull: false)
class TaskFilterOptions with EquatableMixin {
  final bool? acknowledged;
  final StatusEnum? status;
  final String? taskId;
  final TaskNameEnum? taskName;
  final TaskTypeEnum? taskType;
  final TasksViewTypeEnum? type;
  final TriggerSourceEnum? triggerSource;
  final String? ordering;

  const TaskFilterOptions({
    this.acknowledged,
    this.status,
    this.taskId,
    this.taskName,
    this.taskType,
    this.type,
    this.triggerSource,
    this.ordering,
  });

  Map<String, dynamic> toJson() => {
    if (acknowledged != null) 'acknowledged': acknowledged,
    if (status != null) 'status': status!.value,
    if (taskId != null) 'task_id': taskId,
    if (taskName != null) ...{
      'task_name': _toSnakeCase(taskName!.name),
      'task_type': _taskNameToV10(taskName!),
    },
    if (taskType != null) 'task_type': taskType!.value,
    if (type != null) 'type': _toSnakeCase(type!.name),
    if (triggerSource != null) 'trigger_source': triggerSource!.value,
    if (ordering != null) 'ordering': ordering,
  };

  static String _taskNameToV10(TaskNameEnum taskName) => switch (taskName) {
    TaskNameEnum.checkSanity => TaskTypeEnum.sanityCheck.value,
    _ => _toSnakeCase(taskName.name),
  };

  static String _toSnakeCase(String value) => value.replaceAllMapped(
    RegExp('[A-Z]'),
    (match) => '_${match.group(0)!.toLowerCase()}',
  );

  @override
  List<Object?> get props => [
    acknowledged,
    status,
    taskId,
    taskName,
    taskType,
    type,
    triggerSource,
    ordering,
  ];
}
