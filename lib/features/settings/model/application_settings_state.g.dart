// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'application_settings_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApplicationSettingsState _$ApplicationSettingsStateFromJson(
        Map<String, dynamic> json) =>
    ApplicationSettingsState(
      preferredLocaleSubtag: json['preferredLocaleSubtag'] as String,
      preferredThemeMode:
          $enumDecode(_$ThemeModeEnumMap, json['preferredThemeMode']),
      isLocalAuthenticationEnabled:
          json['isLocalAuthenticationEnabled'] as bool,
      preferredViewType:
          $enumDecode(_$ViewTypeEnumMap, json['preferredViewType']),
    );

Map<String, dynamic> _$ApplicationSettingsStateToJson(
        ApplicationSettingsState instance) =>
    <String, dynamic>{
      'isLocalAuthenticationEnabled': instance.isLocalAuthenticationEnabled,
      'preferredLocaleSubtag': instance.preferredLocaleSubtag,
      'preferredThemeMode': _$ThemeModeEnumMap[instance.preferredThemeMode]!,
      'preferredViewType': _$ViewTypeEnumMap[instance.preferredViewType]!,
    };

const _$ThemeModeEnumMap = {
  ThemeMode.system: 'system',
  ThemeMode.light: 'light',
  ThemeMode.dark: 'dark',
};

const _$ViewTypeEnumMap = {
  ViewType.grid: 'grid',
  ViewType.list: 'list',
};
