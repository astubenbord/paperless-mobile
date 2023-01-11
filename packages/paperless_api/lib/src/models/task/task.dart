import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:paperless_api/src/request_utils.dart';
import 'task_status.dart';

part 'task.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Task extends Equatable {
  final int id;
  final String? taskId;
  final String? taskFileName;
  final DateTime dateCreated;
  final DateTime? dateDone;
  final String? type;
  final TaskStatus? status;
  final String? result;
  final bool acknowledged;
  @JsonKey(fromJson: tryParseNullable)
  final int? relatedDocument;

  const Task({
    required this.id,
    this.taskId,
    this.taskFileName,
    required this.dateCreated,
    this.dateDone,
    this.type,
    this.status,
    this.acknowledged = false,
    this.relatedDocument,
    this.result,
  });

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);

  Map<String, dynamic> toJson() => _$TaskToJson(this);

  @override
  List<Object?> get props => [
        id,
        taskId,
        taskFileName,
        dateCreated,
        dateDone,
        type,
        status,
        result,
        acknowledged,
        relatedDocument,
      ];

  Task copyWith({
    int? id,
    String? taskId,
    String? taskFileName,
    DateTime? dateCreated,
    DateTime? dateDone,
    String? type,
    TaskStatus? status,
    String? result,
    bool? acknowledged,
    int? relatedDocument,
  }) {
    return Task(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      dateCreated: dateCreated ?? this.dateCreated,
      acknowledged: acknowledged ?? this.acknowledged,
      dateDone: dateDone ?? this.dateDone,
      relatedDocument: relatedDocument ?? this.relatedDocument,
      result: result ?? this.result,
      status: status ?? this.status,
      taskFileName: taskFileName ?? this.taskFileName,
      type: type ?? this.type,
    );
  }
}
