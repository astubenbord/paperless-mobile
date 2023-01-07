import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/state/repository_state.dart';
import 'package:json_annotation/json_annotation.dart';

part 'storage_path_repository_state.g.dart';

@JsonSerializable()
class StoragePathRepositoryState
    extends RepositoryState<Map<int, StoragePath>> {
  const StoragePathRepositoryState({
    super.values = const {},
    super.hasLoaded = false,
  });

  @override
  StoragePathRepositoryState copyWith(
      {Map<int, StoragePath>? values, bool? hasLoaded}) {
    return StoragePathRepositoryState(
      values: values ?? this.values,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }

  factory StoragePathRepositoryState.fromJson(Map<String, dynamic> json) =>
      _$StoragePathRepositoryStateFromJson(json);

  Map<String, dynamic> toJson() => _$StoragePathRepositoryStateToJson(this);
}
