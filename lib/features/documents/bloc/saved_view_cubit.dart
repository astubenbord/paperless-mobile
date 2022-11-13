import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/core/model/error_message.dart';
import 'package:paperless_mobile/di_initializer.dart';
import 'package:paperless_mobile/features/documents/bloc/saved_view_state.dart';
import 'package:paperless_mobile/features/documents/model/saved_view.model.dart';
import 'package:paperless_mobile/features/documents/repository/saved_views_repository.dart';
import 'package:injectable/injectable.dart';

@singleton
class SavedViewCubit extends Cubit<SavedViewState> {
  SavedViewCubit() : super(SavedViewState(value: {}));

  void selectView(SavedView? view) {
    emit(SavedViewState(value: state.value, selectedSavedViewId: view?.id));
  }

  Future<SavedView> add(SavedView view) async {
    final savedView = await getIt<SavedViewsRepository>().save(view);
    emit(
      SavedViewState(
        value: {...state.value, savedView.id!: savedView},
        selectedSavedViewId: state.selectedSavedViewId,
      ),
    );
    return savedView;
  }

  Future<int> remove(SavedView view) async {
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
  }

  Future<void> initialize() async {
    final views = await getIt<SavedViewsRepository>().getAll();
    final values = {for (var element in views) element.id!: element};
    emit(SavedViewState(value: values));
  }

  void resetSelection() {
    emit(SavedViewState(value: state.value));
  }
}
