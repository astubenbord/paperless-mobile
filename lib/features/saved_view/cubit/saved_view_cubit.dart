import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/saved_view_repository.dart';
import 'package:paperless_mobile/features/saved_view/cubit/saved_view_state.dart';

class SavedViewCubit extends Cubit<SavedViewState> {
  final SavedViewRepository _repository;
  StreamSubscription? _subscription;

  SavedViewCubit(this._repository) : super(SavedViewState(value: {})) {
    _subscription = _repository.savedViews.listen(
      (savedViews) {
        if (savedViews == null) {
          emit(state.copyWith(isLoaded: false));
        } else {
          emit(state.copyWith(value: savedViews, isLoaded: true));
        }
      },
    );
  }

  void selectView(SavedView? view) {
    emit(state.copyWith(
      selectedSavedViewId: view?.id,
      overwriteSelectedSavedViewId: true,
    ));
  }

  Future<SavedView> add(SavedView view) async {
    final savedView = await _repository.create(view);
    emit(state.copyWith(value: {...state.value, savedView.id!: savedView}));
    return savedView;
  }

  Future<int> remove(SavedView view) async {
    final id = await _repository.delete(view);
    if (state.selectedSavedViewId == id) {
      resetSelection();
    }
    return id;
  }

  Future<void> initialize() async {
    final views = await _repository.findAll();
    final values = {for (var element in views) element.id!: element};
    emit(SavedViewState(value: values, isLoaded: true));
  }

  Future<void> reload() => initialize();

  void resetSelection() {
    emit(SavedViewState(
      value: state.value,
      isLoaded: true,
    ));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
