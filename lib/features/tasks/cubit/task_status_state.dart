part of 'task_status_cubit.dart';

class TaskStatusState extends Equatable {
  final Task? task;
  final bool isListening;
  final bool isAcknowledged;

  const TaskStatusState({
    this.task,
    this.isListening = false,
    this.isAcknowledged = false,
  });

  bool get isActive => isListening && !isAcknowledged;

  bool get isSuccess => task?.status == TaskStatus.success;

  String? get taskId => task?.taskId;

  @override
  List<Object> get props => [];

  TaskStatusState copyWith({
    Task? task,
    bool? isListening,
    bool? isAcknowledged,
  }) {
    return TaskStatusState(
      task: task ?? this.task,
      isListening: isListening ?? this.isListening,
      isAcknowledged: isAcknowledged ?? this.isAcknowledged,
    );
  }
}
