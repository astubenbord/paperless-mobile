import 'package:freezed_annotation/freezed_annotation.dart';

part 'ui_settings_view_settings.freezed.dart';
part 'ui_settings_view_settings.g.dart';

@Freezed(toJson: true, fromJson: true)
abstract class UiSettingsViewSettings with _$UiSettingsViewSettings {
  factory UiSettingsViewSettings({
    String? version,
    String? appLogo,
    String? appTitle,
    int? trashDelay,
    bool? emailEnabled,
    bool? tourComplete,
    UiSettingsViewSettingsUpdateChecking? updateChecking,
    UiSettingsViewSettingsPermissions? permissions,
    UiSettingsViewSettingsDateDisplay? dateDisplay,
    UiSettingsViewSettingsSearch? search,
    UiSettingsViewSettingsSavedViews? savedViews,
    bool? auditlogEnabled,
  }) = _UiSettingsViewSettings;

  factory UiSettingsViewSettings.fromJson(Map<String, dynamic> json) =>
      _$UiSettingsViewSettingsFromJson(json);
}

@Freezed(toJson: true, fromJson: true)
abstract class UiSettingsViewSettingsUpdateChecking
    with _$UiSettingsViewSettingsUpdateChecking {
  factory UiSettingsViewSettingsUpdateChecking({
    /// This is dynamic because the backend can return either a string or a boolean due to a deprecated setting.
    dynamic backendSetting,
  }) = _UiSettingsViewSettingsUpdateChecking;

  factory UiSettingsViewSettingsUpdateChecking.fromJson(
    Map<String, dynamic> json,
  ) => _$UiSettingsViewSettingsUpdateCheckingFromJson(json);
}

@Freezed(toJson: true, fromJson: true)
abstract class UiSettingsViewSettingsPermissions
    with _$UiSettingsViewSettingsPermissions {
  factory UiSettingsViewSettingsPermissions({
    int? defaultOwner,
    @Default([]) List<int>? defaultEditUsers,
    @Default([]) List<int>? defaultViewUsers,
    @Default([]) List<int>? defaultEditGroups,
    @Default([]) List<int>? defaultViewGroups,
  }) = _UiSettingsViewSettingsPermissions;

  factory UiSettingsViewSettingsPermissions.fromJson(
    Map<String, dynamic> json,
  ) => _$UiSettingsViewSettingsPermissionsFromJson(json);
}

@JsonEnum(valueField: 'value')
enum UiSettingsViewSettingsDateDisplayFormat {
  short('shortDate'),
  medium('mediumDate'),
  long('longDate');

  final String value;
  const UiSettingsViewSettingsDateDisplayFormat(this.value);
}

@Freezed(toJson: true, fromJson: true)
abstract class UiSettingsViewSettingsDateDisplay
    with _$UiSettingsViewSettingsDateDisplay {
  factory UiSettingsViewSettingsDateDisplay({
    @Default(UiSettingsViewSettingsDateDisplayFormat.medium)
    UiSettingsViewSettingsDateDisplayFormat? dateFormat,
    String? dateLocale,
  }) = _UiSettingsViewSettingsDateDisplay;

  factory UiSettingsViewSettingsDateDisplay.fromJson(
    Map<String, dynamic> json,
  ) => _$UiSettingsViewSettingsDateDisplayFromJson(json);
}

@JsonEnum(valueField: 'value')
enum UiSettingsViewSettingsSearchMoreLink {
  titleContent('title-content'),
  advanced('advanced');

  final String value;
  const UiSettingsViewSettingsSearchMoreLink(this.value);
}

@Freezed(toJson: true, fromJson: true)
abstract class UiSettingsViewSettingsSearch
    with _$UiSettingsViewSettingsSearch {
  factory UiSettingsViewSettingsSearch({
    @Default(UiSettingsViewSettingsSearchMoreLink.titleContent)
    UiSettingsViewSettingsSearchMoreLink? moreLink,
  }) = _UiSettingsViewSettingsSearch;

  factory UiSettingsViewSettingsSearch.fromJson(Map<String, dynamic> json) =>
      _$UiSettingsViewSettingsSearchFromJson(json);
}

@Freezed(toJson: true, fromJson: true)
abstract class UiSettingsViewSettingsSavedViews
    with _$UiSettingsViewSettingsSavedViews {
  factory UiSettingsViewSettingsSavedViews({
    List<int>? dashboardViewsSortOrder,
  }) = _UiSettingsViewSettingsSavedViews;

  factory UiSettingsViewSettingsSavedViews.fromJson(
    Map<String, dynamic> json,
  ) => _$UiSettingsViewSettingsSavedViewsFromJson(json);
}
