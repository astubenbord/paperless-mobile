import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/core/repository/state/repository_state.dart';
import 'package:paperless_mobile/features/labels/bloc/label_state.dart';

class LabelCubit<T extends Label> extends Cubit<LabelState<T>> {
  final LabelRepository<T, RepositoryState> _repository;

  late StreamSubscription _subscription;

  LabelCubit(LabelRepository<T, RepositoryState> repository)
      : _repository = repository,
        super(LabelState(
          isLoaded: repository.isInitialized,
          labels: repository.current?.values ?? {},
        )) {
    _subscription = _repository.values.listen(
      (event) {
        if (event == null) {
          emit(LabelState());
        }
        emit(LabelState(isLoaded: true, labels: event!.values));
      },
    );
  }

  ///
  /// Adds  [item] to the current state. A new state is automatically pushed
  /// due to the subscription to the repository, which updates the state on
  /// operation.
  ///
  Future<T> add(T item) async {
    assert(item.id == null);
    final addedItem = await _repository.create(item);
    return addedItem;
  }

  Future<void> reload() {
    return _repository.findAll();
  }

  Future<T> replace(T item) async {
    assert(item.id != null);
    final updatedItem = await _repository.update(item);
    return updatedItem;
  }

  Future<void> remove(T item) async {
    assert(item.id != null);
    if (state.labels.containsKey(item.id)) {
      await _repository.delete(item);
    }
  }

  void reset() {
    emit(LabelState(isLoaded: false, labels: {}));
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
