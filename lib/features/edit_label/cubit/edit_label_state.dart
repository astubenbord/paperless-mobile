import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

@immutable
class EditLabelState<T> extends Equatable {
  final Map<int, T> labels;

  const EditLabelState({required this.labels});

  @override
  List<Object> get props => [labels];
}

class EditLabelInitial<T> extends EditLabelState<T> {
  const EditLabelInitial() : super(labels: const {});
}
