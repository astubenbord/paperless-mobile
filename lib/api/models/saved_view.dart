import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:paperless_mobile/api/models/display_mode_enum.dart';
import 'package:paperless_mobile/api/models/saved_view_filter_rule.dart';

part 'saved_view.freezed.dart';
part 'saved_view.g.dart';

@Freezed(toJson: false, fromJson: true)
abstract class SavedView with _$SavedView {
  factory SavedView({
    required int id,
    required String name,
    @Default(false) bool showOnDashboard,
    @Default(false) bool showInSidebar,
    String? sortField,
    bool? sortReverse,
    required List<SavedViewFilterRule> filterRules,
    // minimum: 1
    // maximum: 2147483647
    int? pageSize,
    DisplayModeEnum? displayMode,
    List<String>? displayFields,
    int? owner,
    required bool? userCanChange,
  }) = _SavedView;

  factory SavedView.fromJson(Map<String, dynamic> json) =>
      _$SavedViewFromJson(json);
}
