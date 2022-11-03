import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/core/bloc/global_error_cubit.dart';
import 'package:paperless_mobile/core/model/error_message.dart';
import 'package:paperless_mobile/features/labels/model/label.model.dart';
import 'package:paperless_mobile/features/labels/repository/label_repository.dart';

abstract class LabelCubit<T extends Label> extends Cubit<Map<int, T>> {
  final LabelRepository labelRepository;
  final GlobalErrorCubit errorCubit;

  LabelCubit(this.labelRepository, this.errorCubit) : super({});

  @protected
  void loadFrom(Iterable<T> items) =>
      emit(Map.fromIterable(items, key: (e) => (e as T).id!));

  Future<T> add(
    T item, {
    bool propagateEventOnError = true,
  }) async {
    assert(item.id == null);
    try {
      final addedItem = await save(item);
      final newState = {...state};
      newState.putIfAbsent(addedItem.id!, () => addedItem);
      emit(newState);
      return addedItem;
    } on ErrorMessage catch (error) {
      if (propagateEventOnError) {
        errorCubit.add(error);
      }
      return Future.error(error);
    }
  }

  Future<T> replace(
    T item, {
    bool propagateEventOnError = true,
  }) async {
    assert(item.id != null);
    try {
      final updatedItem = await update(item);
      final newState = {...state};
      newState[item.id!] = updatedItem;
      emit(newState);
      return updatedItem;
    } on ErrorMessage catch (error) {
      if (propagateEventOnError) {
        errorCubit.add(error);
      }
      return Future.error(error);
    }
  }

  Future<void> remove(
    T item, {
    bool propagateEventOnError = true,
  }) async {
    assert(item.id != null);
    if (state.containsKey(item.id)) {
      try {
        final deletedId = await delete(item);
        final newState = {...state};
        newState.remove(deletedId);
        emit(newState);
      } on ErrorMessage catch (error) {
        if (propagateEventOnError) {
          errorCubit.add(error);
        }
        return Future.error(error);
      }
    }
  }

  void reset() => emit({});

  Future<void> initialize();

  @protected
  Future<T> save(T item);

  @protected
  Future<T> update(T item);

  @protected
  Future<int> delete(T item);
}
