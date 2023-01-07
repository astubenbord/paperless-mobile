import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/saved_view_repository.dart';
import 'package:paperless_mobile/features/saved_view/cubit/saved_view_state.dart';

class SavedViewCubit extends Cubit<SavedViewState> {
  final SavedViewRepository _repository;
  StreamSubscription? _subscription;

  SavedViewCubit(this._repository) : super(const SavedViewState()) {
    _subscription = _repository.values.listen(
      (savedViews) {
        if (savedViews?.hasLoaded ?? false) {
          emit(state.copyWith(value: savedViews?.values, hasLoaded: true));
        } else {
          emit(state.copyWith(hasLoaded: false));
        }
      },
    );
  }

  Future<SavedView> add(SavedView view) async {
    final savedView = await _repository.create(view);
    emit(state.copyWith(value: {...state.value, savedView.id!: savedView}));
    return savedView;
  }

  Future<int> remove(SavedView view) {
    return _repository.delete(view);
  }

  Future<void> initialize() async {
    final views = await _repository.findAll();
    final values = {for (var element in views) element.id!: element};
    emit(SavedViewState(value: values, hasLoaded: true));
  }

  Future<void> reload() => initialize();

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
