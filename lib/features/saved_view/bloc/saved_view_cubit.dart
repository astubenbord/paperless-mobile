import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/features/saved_view/bloc/saved_view_state.dart';

@prod
@test
@lazySingleton
class SavedViewCubit extends Cubit<SavedViewState> {
  final PaperlessSavedViewsApi _api;
  SavedViewCubit(this._api) : super(SavedViewState(value: {}));

  void selectView(SavedView? view) {
    emit(SavedViewState(value: state.value, selectedSavedViewId: view?.id));
  }

  Future<SavedView> add(SavedView view) async {
    final savedView = await _api.save(view);
    emit(
      SavedViewState(
        value: {...state.value, savedView.id!: savedView},
        selectedSavedViewId: state.selectedSavedViewId,
      ),
    );
    return savedView;
  }

  Future<int> remove(SavedView view) async {
    final id = await _api.delete(view);
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
    final views = await _api.getAll();
    final values = {for (var element in views) element.id!: element};
    emit(SavedViewState(value: values));
  }

  void resetSelection() {
    emit(SavedViewState(value: state.value));
  }
}
