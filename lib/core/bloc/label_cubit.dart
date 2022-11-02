import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/features/labels/model/label.model.dart';
import 'package:paperless_mobile/features/labels/repository/label_repository.dart';

abstract class LabelCubit<T extends Label> extends Cubit<Map<int, T>> {
  final LabelRepository labelRepository;
  LabelCubit(this.labelRepository) : super({});

  @protected
  void loadFrom(Iterable<T> items) => emit(Map.fromIterable(items, key: (e) => (e as T).id!));

  Future<T> add(T item) async {
    assert(item.id == null);
    final addedItem = await save(item);
    final newState = {...state};
    newState.putIfAbsent(addedItem.id!, () => addedItem);
    emit(newState);
    return addedItem;
  }

  Future<T> replace(T item) async {
    assert(item.id != null);
    final updatedItem = await update(item);
    final newState = {...state};
    newState[item.id!] = updatedItem;
    emit(newState);
    return updatedItem;
  }

  Future<void> remove(T item) async {
    assert(item.id != null);
    if (state.containsKey(item.id)) {
      final deletedId = await delete(item);
      final newState = {...state};
      newState.remove(deletedId);
      emit(newState);
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
