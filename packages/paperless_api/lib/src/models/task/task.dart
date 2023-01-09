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
  final int? relatedDocumentId;

  const Task({
    required this.id,
    this.taskId,
    this.taskFileName,
    required this.dateCreated,
    this.dateDone,
    this.type,
    this.status,
    this.acknowledged = false,
    this.relatedDocumentId,
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
        relatedDocumentId,
      ];
}
