import 'package:equatable/equatable.dart';
import 'package:paperless_api/paperless_api.dart';

class SavedViewState with EquatableMixin {
  final Map<int, SavedView> value;
  final int? selectedSavedViewId;

  SavedViewState({
    required this.value,
    this.selectedSavedViewId,
  });

  @override
  List<Object?> get props => [
        value,
        selectedSavedViewId,
      ];

  SavedViewState copyWith({
    Map<int, SavedView>? value,
    int? selectedSavedViewId,
    bool overwriteSelectedSavedViewId = false,
  }) {
    return SavedViewState(
      value: value ?? this.value,
      selectedSavedViewId: overwriteSelectedSavedViewId
          ? selectedSavedViewId
          : this.selectedSavedViewId,
    );
  }
}
