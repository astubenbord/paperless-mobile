import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:paperless_mobile/api/models/display_mode_enum.dart';
import 'package:paperless_mobile/api/models/correspondent_request_set_permissions.dart';
import 'package:paperless_mobile/api/models/saved_view_filter_rule_request.dart';

part 'saved_view_request.freezed.dart';
part 'saved_view_request.g.dart';

@Freezed(toJson: true, fromJson: false)
abstract class SavedViewRequest with _$SavedViewRequest {
  factory SavedViewRequest({
    required String name,
    required bool showOnDashboard,
    required bool showInSidebar,
    String? icon,
    String? sortField,
    bool? sortReverse,
    required List<SavedViewFilterRuleRequest> filterRules,
    // minimum: 1
    // maximum: 2147483647
    int? pageSize,
    DisplayModeEnum? displayMode,
    List<String>? displayFields,
    int? owner,
    CorrespondentRequestSetPermissions? setPermissions,
  }) = _SavedViewRequest;
}
