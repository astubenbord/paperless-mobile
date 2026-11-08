import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:paperless_mobile/api/models/ui_settings_view_settings.dart';
import 'package:paperless_mobile/api/models/ui_settings_view_user.dart';

part 'ui_settings_view.freezed.dart';
part 'ui_settings_view.g.dart';

@Freezed(toJson: true, fromJson: true)
abstract class UiSettingsView with _$UiSettingsView {
  factory UiSettingsView({
    int? id,
    List<String>? permissions,
    UiSettingsViewSettings? settings,
    required UiSettingsViewUser user,
  }) = _UiSettingsView;

  factory UiSettingsView.fromJson(Map<String, dynamic> json) =>
      _$UiSettingsViewFromJson(json);
}
