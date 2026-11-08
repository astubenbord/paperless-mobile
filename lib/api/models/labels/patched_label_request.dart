import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:paperless_mobile/api/models/models.dart';
import 'package:paperless_mobile/api/utils/patched_value.dart';

part 'patched_label_request.g.dart';

sealed class PatchedLabelRequest {
  PatchedLabelRequest({
    this.name,
    this.match,
    this.matchingAlgorithm,
    this.isInsensitive,
    this.owner,
    this.setPermissions,
  });

  @JsonKey(name: r'name', includeIfNull: false)
  final PatchedValue<String?>? name;

  @JsonKey(name: r'match', includeIfNull: false)
  final PatchedValue<String?>? match;

  // minimum: 0.0
  // maximum: 2.147483647E9
  @JsonKey(name: r'matching_algorithm', includeIfNull: false)
  final PatchedValue<MatchingAlgorithm?>? matchingAlgorithm;

  @JsonKey(name: r'is_insensitive', includeIfNull: false)
  final PatchedValue<bool?>? isInsensitive;

  @JsonKey(name: r'owner', includeIfNull: false)
  final PatchedValue<int?>? owner;

  @JsonKey(name: r'set_permissions', includeIfNull: false)
  final CorrespondentRequestSetPermissions? setPermissions;

  Map<String, dynamic> toJson();
}

@CopyWith()
@JsonSerializable(
  createToJson: true,
  createFactory: false,
  includeIfNull: false,
)
class PatchedCorrespondentRequest extends PatchedLabelRequest {
  PatchedCorrespondentRequest({
    super.name,
    super.match,
    super.matchingAlgorithm,
    super.isInsensitive,
    super.owner,
    super.setPermissions,
  });
  @override
  Map<String, dynamic> toJson() =>
      processPatchedValueJson(_$PatchedCorrespondentRequestToJson(this));
}

@CopyWith()
@JsonSerializable(
  createToJson: true,
  createFactory: false,
  includeIfNull: false,
)
class PatchedTagRequest extends PatchedLabelRequest {
  PatchedTagRequest({
    super.name,
    super.match,
    super.matchingAlgorithm,
    super.isInsensitive,
    super.owner,
    super.setPermissions,
    this.isInboxTag,
    this.color,
    this.parent,
  });

  @JsonKey(name: r'color', includeIfNull: false)
  final PatchedValue<String?>? color;

  /// Marks this tag as an inbox tag: All newly consumed documents will be tagged with inbox tags.
  @JsonKey(name: r'is_inbox_tag', includeIfNull: false)
  final PatchedValue<bool?>? isInboxTag;

  @JsonKey(name: r'parent', includeIfNull: false)
  final PatchedValue<int?>? parent;

  @override
  Map<String, dynamic> toJson() =>
      processPatchedValueJson(_$PatchedTagRequestToJson(this));
}

@CopyWith()
@JsonSerializable(
  createToJson: true,
  createFactory: false,
  includeIfNull: false,
)
class PatchedDocumentTypeRequest extends PatchedLabelRequest {
  PatchedDocumentTypeRequest({
    super.name,
    super.match,
    super.matchingAlgorithm,
    super.isInsensitive,
    super.owner,
    super.setPermissions,
  });

  @override
  Map<String, dynamic> toJson() =>
      processPatchedValueJson(_$PatchedDocumentTypeRequestToJson(this));
}

@CopyWith()
@JsonSerializable(
  createToJson: true,
  createFactory: false,
  includeIfNull: false,
)
class PatchedStoragePathRequest extends PatchedLabelRequest {
  PatchedStoragePathRequest({
    super.name,
    this.path,
    super.match,
    super.matchingAlgorithm,
    super.isInsensitive,
    super.owner,
    super.setPermissions,
  });

  @JsonKey(name: r'path', includeIfNull: false)
  final PatchedValue<String?>? path;

  @override
  Map<String, dynamic> toJson() =>
      processPatchedValueJson(_$PatchedStoragePathRequestToJson(this));
}
