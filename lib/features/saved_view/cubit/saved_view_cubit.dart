import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/saved_view_repository.dart';
import 'package:paperless_mobile/features/saved_view/cubit/saved_view_state.dart';

class SavedViewCubit extends Cubit<SavedViewState> {
  final SavedViewRepository _repository;
  StreamSubscription? _subscription;

  SavedViewCubit(this._repository) : super(SavedViewState(value: {})) {
    _subscription = _repository.savedViews.listen(
      (savedViews) => emit(state.copyWith(value: savedViews)),
    );
  }

  void selectView(SavedView? view) {
    emit(SavedViewState(value: state.value, selectedSavedViewId: view?.id));
  }

  Future<SavedView> add(SavedView view) async {
    final savedView = await _repository.create(view);
    emit(
      SavedViewState(
        value: {...state.value, savedView.id!: savedView},
        selectedSavedViewId: state.selectedSavedViewId,
      ),
    );
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
    emit(SavedViewState(value: values));
  }

  void resetSelection() {
    emit(SavedViewState(value: state.value));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
