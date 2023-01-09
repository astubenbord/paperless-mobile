// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Task _$TaskFromJson(Map<String, dynamic> json) => Task(
      id: json['id'] as int,
      taskId: json['task_id'] as String?,
      taskFileName: json['task_file_name'] as String?,
      dateCreated: DateTime.parse(json['date_created'] as String),
      dateDone: json['date_done'] == null
          ? null
          : DateTime.parse(json['date_done'] as String),
      type: json['type'] as String?,
      status: $enumDecodeNullable(_$TaskStatusEnumMap, json['status']),
      acknowledged: json['acknowledged'] as bool? ?? false,
      relatedDocumentId:
          tryParseNullable(json['related_document_id'] as String?),
      result: json['result'] as String?,
    );

Map<String, dynamic> _$TaskToJson(Task instance) => <String, dynamic>{
      'id': instance.id,
      'task_id': instance.taskId,
      'task_file_name': instance.taskFileName,
      'date_created': instance.dateCreated.toIso8601String(),
      'date_done': instance.dateDone?.toIso8601String(),
      'type': instance.type,
      'status': _$TaskStatusEnumMap[instance.status],
      'result': instance.result,
      'acknowledged': instance.acknowledged,
      'related_document_id': instance.relatedDocumentId,
    };

const _$TaskStatusEnumMap = {
  TaskStatus.started: 'STARTED',
  TaskStatus.pending: 'PENDING',
  TaskStatus.failure: 'FAILURE',
  TaskStatus.success: 'SUCCESS',
};
