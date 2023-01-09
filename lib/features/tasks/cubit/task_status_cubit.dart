import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:paperless_api/paperless_api.dart';
part 'task_status_state.dart';

class TaskStatusCubit extends Cubit<TaskStatusState> {
  final PaperlessTasksApi _api;
  TaskStatusCubit(this._api) : super(const TaskStatusState());

  void startListeningToTask(String taskId) {
    _api
        .listenForTaskChanges(taskId)
        .forEach(
          (element) => TaskStatusState(
            isListening: true,
            isAcknowledged: false,
            task: element,
          ),
        )
        .whenComplete(() => emit(state.copyWith(isListening: false)));
  }

  void acknowledgeCurrentTask() {
    emit(state.copyWith(isListening: false, isAcknowledged: true));
  }
}
