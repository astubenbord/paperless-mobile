import 'package:equatable/equatable.dart';
import 'package:paperless_mobile/features/documents/model/saved_view.model.dart';

class SavedViewState with EquatableMixin {
  final Map<int, SavedView> value;
  final int? selectedSavedViewId;

  SavedViewState({
    required this.value,
    this.selectedSavedViewId,
  });

  @override
  List<Object?> get props => [value, selectedSavedViewId];
}
