import 'dart:io';

import 'package:flutter/material.dart';
import 'package:paperless_mobile/core/type/json.dart';

///
/// State holding the current application settings such as selected language, theme mode and more.
///
///
class ApplicationSettingsState {
  static final defaultSettings = ApplicationSettingsState(
    isLocalAuthenticationEnabled: false,
    preferredLocaleSubtag: Platform.localeName.split('_').first,
    preferredThemeMode: ThemeMode.system,
  );

  static const isLocalAuthenticationEnabledKey = "isLocalAuthenticationEnabled";
  static const preferredLocaleSubtagKey = "localeSubtag";
  static const preferredThemeModeKey = "preferredThemeModeKey";

  final bool isLocalAuthenticationEnabled;
  final String preferredLocaleSubtag;

  final ThemeMode preferredThemeMode;

  ApplicationSettingsState({
    required this.preferredLocaleSubtag,
    required this.preferredThemeMode,
    required this.isLocalAuthenticationEnabled,
  });

  JSON toJson() {
    return {
      isLocalAuthenticationEnabledKey: isLocalAuthenticationEnabled,
      preferredLocaleSubtagKey: preferredLocaleSubtag,
      preferredThemeModeKey: preferredThemeMode.index,
    };
  }

  ApplicationSettingsState.fromJson(JSON json)
      : isLocalAuthenticationEnabled =
            json[isLocalAuthenticationEnabledKey] ?? defaultSettings.isLocalAuthenticationEnabled,
        preferredLocaleSubtag =
            json[preferredLocaleSubtagKey] ?? Platform.localeName.split("_").first,
        preferredThemeMode = json[preferredThemeModeKey] != null
            ? ThemeMode.values[(json[preferredThemeModeKey])]
            : defaultSettings.preferredThemeMode;

  ApplicationSettingsState copyWith({
    bool? isLocalAuthenticationEnabled,
    String? preferredLocaleSubtag,
    ThemeMode? preferredThemeMode,
  }) {
    return ApplicationSettingsState(
      isLocalAuthenticationEnabled:
          isLocalAuthenticationEnabled ?? this.isLocalAuthenticationEnabled,
      preferredLocaleSubtag: preferredLocaleSubtag ?? this.preferredLocaleSubtag,
      preferredThemeMode: preferredThemeMode ?? this.preferredThemeMode,
    );
  }
}
