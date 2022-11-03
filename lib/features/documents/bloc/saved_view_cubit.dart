import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/core/bloc/global_error_cubit.dart';
import 'package:paperless_mobile/core/model/error_message.dart';
import 'package:paperless_mobile/di_initializer.dart';
import 'package:paperless_mobile/features/documents/bloc/saved_view_state.dart';
import 'package:paperless_mobile/features/documents/model/saved_view.model.dart';
import 'package:paperless_mobile/features/documents/repository/saved_views_repository.dart';
import 'package:injectable/injectable.dart';

@singleton
class SavedViewCubit extends Cubit<SavedViewState> {
  final GlobalErrorCubit errorCubit;
  SavedViewCubit(this.errorCubit) : super(SavedViewState(value: {}));

  void selectView(SavedView? view, {bool propagateEventOnError = true}) {
    try {
      emit(SavedViewState(value: state.value, selectedSavedViewId: view?.id));
    } on ErrorMessage catch (error) {
      if (propagateEventOnError) {
        errorCubit.add(error);
      }
      rethrow;
    }
  }

  Future<SavedView> add(
    SavedView view, {
    bool propagateEventOnError = true,
  }) async {
    try {
      final savedView = await getIt<SavedViewsRepository>().save(view);
      emit(
        SavedViewState(
          value: {...state.value, savedView.id!: savedView},
          selectedSavedViewId: state.selectedSavedViewId,
        ),
      );
      return savedView;
    } on ErrorMessage catch (error) {
      if (propagateEventOnError) {
        errorCubit.add(error);
      }
      rethrow;
    }
  }

  Future<int> remove(
    SavedView view, {
    bool propagateEventOnError = true,
  }) async {
    try {
      final id = await getIt<SavedViewsRepository>().delete(view);
      final newValue = {...state.value};
      newValue.removeWhere((key, value) => key == id);
      emit(
        SavedViewState(
          value: newValue,
          selectedSavedViewId: view.id == state.selectedSavedViewId
              ? null
              : state.selectedSavedViewId,
        ),
      );
      return id;
    } on ErrorMessage catch (error) {
      if (propagateEventOnError) {
        errorCubit.add(error);
      }
      rethrow;
    }
  }

  Future<void> initialize({
    bool propagateEventOnError = true,
  }) async {
    try {
      final views = await getIt<SavedViewsRepository>().getAll();
      final values = {for (var element in views) element.id!: element};
      emit(SavedViewState(value: values));
    } on ErrorMessage catch (error) {
      if (propagateEventOnError) {
        errorCubit.add(error);
      }
      rethrow;
    }
  }

  void resetSelection() {
    emit(SavedViewState(value: state.value));
  }
}
