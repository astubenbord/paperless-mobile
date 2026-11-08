import 'package:paperless_mobile/core/bloc/loading_status.dart';

class BaseState<T> {
  final Object? error;
  final T? value;
  final LoadingStatus status;

  BaseState({required this.error, required this.value, required this.status});

  BaseState<T> copyWith({Object? error, T? value, LoadingStatus? status}) {
    return BaseState(
      error: error ?? this.error,
      value: value ?? this.value,
      status: status ?? this.status,
    );
  }
}
