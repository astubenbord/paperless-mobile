part of 'task_status_cubit.dart';

class TaskStatusState extends Equatable {
  final Task? task;
  final bool isListening;

  const TaskStatusState({
    this.task,
    this.isListening = false,
  });

  bool get isSuccess => task?.status == TaskStatus.success;

  bool get isAcknowledged => task?.acknowledged ?? false;

  String? get taskId => task?.taskId;

  @override
  List<Object?> get props => [task, isListening];

  TaskStatusState copyWith({
    Task? task,
    bool? isListening,
    bool? isAcknowledged,
  }) {
    return TaskStatusState(
      task: task ?? this.task,
      isListening: isListening ?? this.isListening,
    );
  }
}
