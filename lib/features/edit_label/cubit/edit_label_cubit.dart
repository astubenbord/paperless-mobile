import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/core/repository/state/repository_state.dart';
import 'package:paperless_mobile/features/edit_label/cubit/edit_label_state.dart';

class EditLabelCubit<T extends Label> extends Cubit<EditLabelState<T>> {
  final LabelRepository<T, RepositoryState<Map<int, T>>> _repository;

  StreamSubscription? _subscription;

  EditLabelCubit(LabelRepository<T, RepositoryState<Map<int, T>>> repository)
      : _repository = repository,
        super(const EditLabelInitial()) {
    _subscription = repository.values.listen(
      (event) => emit(EditLabelState(labels: event?.values ?? {})),
    );
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
