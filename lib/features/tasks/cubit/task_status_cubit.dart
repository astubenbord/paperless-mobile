import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:paperless_api/paperless_api.dart';
part 'task_status_state.dart';

class TaskStatusCubit extends Cubit<TaskStatusState> {
  final PaperlessTasksApi _api;
  TaskStatusCubit(this._api) : super(const TaskStatusState());

  void listenToTaskChanges(String taskId) {
    _api
        .listenForTaskChanges(taskId)
        .forEach(
          (element) => emit(
            TaskStatusState(
              isListening: true,
              task: element,
            ),
          ),
        )
        .whenComplete(() => emit(state.copyWith(isListening: false)));
  }

  Future<void> acknowledgeCurrentTask() async {
    if (state.task == null) {
      return;
    }
    final task = await _api.acknowledgeTask(state.task!);
    emit(
      state.copyWith(
        task: task,
        isListening: false,
      ),
    );
  }
}
