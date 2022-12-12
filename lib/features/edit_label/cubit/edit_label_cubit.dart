import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/features/edit_label/cubit/edit_label_state.dart';

class EditLabelCubit<T extends Label> extends Cubit<EditLabelState<T>> {
  final LabelRepository<T> _repository;

  StreamSubscription<Map<int, T>>? _subscription;

  EditLabelCubit(LabelRepository<T> repository)
      : _repository = repository,
        super(const EditLabelInitial()) {
    _subscription = _repository.labels
        .listen((labels) => emit(EditLabelState(labels: labels)));
  }

  Future<T> create(T label) => _repository.create(label);

  Future<T> update(T label) => _repository.update(label);

  Future<void> delete(T label) => _repository.delete(label);

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
