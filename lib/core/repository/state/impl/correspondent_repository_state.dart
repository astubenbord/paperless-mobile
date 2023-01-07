import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/state/repository_state.dart';

part 'correspondent_repository_state.g.dart';

@JsonSerializable()
class CorrespondentRepositoryState
    extends RepositoryState<Map<int, Correspondent>> {
  const CorrespondentRepositoryState({
    super.values = const {},
    super.hasLoaded,
  });

  @override
  CorrespondentRepositoryState copyWith({
    Map<int, Correspondent>? values,
    bool? hasLoaded,
  }) {
    return CorrespondentRepositoryState(
      values: values ?? this.values,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }

  factory CorrespondentRepositoryState.fromJson(Map<String, dynamic> json) =>
      _$CorrespondentRepositoryStateFromJson(json);

  Map<String, dynamic> toJson() => _$CorrespondentRepositoryStateToJson(this);
}
