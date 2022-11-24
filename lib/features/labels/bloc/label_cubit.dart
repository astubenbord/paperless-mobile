import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/features/labels/model/label.model.dart';
import 'package:paperless_mobile/features/labels/model/label_state.dart';
import 'package:paperless_mobile/features/labels/repository/label_repository.dart';

abstract class LabelCubit<T extends Label> extends Cubit<LabelState<T>> {
  final LabelRepository labelRepository;

  LabelCubit(this.labelRepository) : super(LabelState.initial());

  @protected
  void loadFrom(Iterable<T> items) {
    emit(
      LabelState(
        isLoaded: true,
        labels: Map.fromIterable(items, key: (e) => (e as T).id!),
      ),
    );
  }

  Future<T> add(T item) async {
    assert(item.id == null);
    final addedItem = await save(item);
    final newValues = {...state.labels};
    newValues.putIfAbsent(addedItem.id!, () => addedItem);
    emit(
      LabelState(
        isLoaded: true,
        labels: newValues,
      ),
    );
    return addedItem;
  }

  Future<T> replace(T item) async {
    assert(item.id != null);
    final updatedItem = await update(item);
    final updatedValues = {...state.labels};
    updatedValues[item.id!] = updatedItem;
    emit(
      LabelState(
        isLoaded: state.isLoaded,
        labels: updatedValues,
      ),
    );
    return updatedItem;
  }

  Future<void> remove(T item) async {
    assert(item.id != null);
    if (state.labels.containsKey(item.id)) {
      final deletedId = await delete(item);
      final updatedValues = {...state.labels}..remove(deletedId);
      emit(
        LabelState(isLoaded: true, labels: updatedValues),
      );
    }
  }

  void reset() {
    emit(LabelState(isLoaded: false, labels: {}));
  }

  Future<void> initialize();

  @protected
  Future<T> save(T item);

  @protected
  Future<T> update(T item);

  @protected
  Future<int> delete(T item);
}
