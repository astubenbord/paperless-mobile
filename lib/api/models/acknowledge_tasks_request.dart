import 'package:freezed_annotation/freezed_annotation.dart';

part 'acknowledge_tasks_request.freezed.dart';
part 'acknowledge_tasks_request.g.dart';

@Freezed(toJson: true, fromJson: false)
abstract class AcknowledgeTasksRequest with _$AcknowledgeTasksRequest {
  factory AcknowledgeTasksRequest({
    @Default([]) List<int> tasks,
    @Default(false) bool all,
  }) = _AcknowledgeTasksRequest;
}
