import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/state/repository_state.dart';
import 'package:json_annotation/json_annotation.dart';

part 'saved_view_repository_state.g.dart';

@JsonSerializable()
class SavedViewRepositoryState extends RepositoryState<Map<int, SavedView>> {
  const SavedViewRepositoryState({
    super.values = const {},
    super.hasLoaded = false,
  });

  @override
  SavedViewRepositoryState copyWith({
    Map<int, SavedView>? values,
    bool? hasLoaded,
  }) {
    return SavedViewRepositoryState(
      values: values ?? this.values,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }

  factory SavedViewRepositoryState.fromJson(Map<String, dynamic> json) =>
      _$SavedViewRepositoryStateFromJson(json);

  Map<String, dynamic> toJson() => _$SavedViewRepositoryStateToJson(this);
}
