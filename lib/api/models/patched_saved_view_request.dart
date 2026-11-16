import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:paperless_mobile/api/models/display_mode_enum.dart';
import 'package:paperless_mobile/api/models/saved_view_filter_rule_request.dart';
import 'package:paperless_mobile/api/models/correspondent_request_set_permissions.dart';
import 'package:paperless_mobile/api/utils/patched_value.dart';

part 'patched_saved_view_request.g.dart';

@JsonSerializable(
  createFactory: false,
  createToJson: true,
  includeIfNull: false,
)
class PatchedSavedViewRequest {
  final PatchedValue<String?>? name;
  final PatchedValue<String?>? icon;
  final PatchedValue<bool?>? showOnDashboard;
  final PatchedValue<bool?>? showInSidebar;
  final PatchedValue<String?>? sortField;
  final PatchedValue<bool?>? sortReverse;
  final PatchedValue<List<SavedViewFilterRuleRequest>?>? filterRules;

  // minimum: 1
  // maximum: 2147483647
  final PatchedValue<int?>? pageSize;
  final PatchedValue<DisplayModeEnum?>? displayMode;
  final PatchedValue<List<String>?>? displayFields;
  final PatchedValue<int?>? owner;
  final CorrespondentRequestSetPermissions? setPermissions;

  PatchedSavedViewRequest({
    this.name,
    this.icon,
    this.showOnDashboard,
    this.showInSidebar,
    this.sortField,
    this.sortReverse,
    this.filterRules,
    this.pageSize,
    this.displayMode,
    this.displayFields,
    this.owner,
    this.setPermissions,
  });

  Map<String, dynamic> toJson() =>
      processPatchedValueJson(_$PatchedSavedViewRequestToJson(this));
}
