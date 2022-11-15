import 'dart:io';

import 'package:flutter/material.dart';
import 'package:paperless_mobile/core/type/types.dart';
import 'package:paperless_mobile/features/settings/model/view_type.dart';

///
/// State holding the current application settings such as selected language, theme mode and more.
///
///
class ApplicationSettingsState {
  static final defaultSettings = ApplicationSettingsState(
    isLocalAuthenticationEnabled: false,
    preferredLocaleSubtag: Platform.localeName.split('_').first,
    preferredThemeMode: ThemeMode.system,
    preferredViewType: ViewType.list,
  );

  static const isLocalAuthenticationEnabledKey = "isLocalAuthenticationEnabled";
  static const preferredLocaleSubtagKey = "localeSubtag";
  static const preferredThemeModeKey = "preferredThemeModeKey";
  static const preferredViewTypeKey = 'preferredViewType';

  final bool isLocalAuthenticationEnabled;
  final String preferredLocaleSubtag;
  final ThemeMode preferredThemeMode;
  final ViewType preferredViewType;

  ApplicationSettingsState({
    required this.preferredLocaleSubtag,
    required this.preferredThemeMode,
    required this.isLocalAuthenticationEnabled,
    required this.preferredViewType,
  });

  JSON toJson() {
    return {
      isLocalAuthenticationEnabledKey: isLocalAuthenticationEnabled,
      preferredLocaleSubtagKey: preferredLocaleSubtag,
      preferredThemeModeKey: preferredThemeMode.name,
      preferredViewTypeKey: preferredViewType.name,
    };
  }

  ApplicationSettingsState.fromJson(JSON json)
      : isLocalAuthenticationEnabled = json[isLocalAuthenticationEnabledKey],
        preferredLocaleSubtag = json[preferredLocaleSubtagKey],
        preferredThemeMode =
            ThemeMode.values.byName(json[preferredThemeModeKey]),
        preferredViewType = ViewType.values.byName(json[preferredViewTypeKey]);

  ApplicationSettingsState copyWith({
    bool? isLocalAuthenticationEnabled,
    String? preferredLocaleSubtag,
    ThemeMode? preferredThemeMode,
    ViewType? preferredViewType,
  }) {
    return ApplicationSettingsState(
      isLocalAuthenticationEnabled:
          isLocalAuthenticationEnabled ?? this.isLocalAuthenticationEnabled,
      preferredLocaleSubtag:
          preferredLocaleSubtag ?? this.preferredLocaleSubtag,
      preferredThemeMode: preferredThemeMode ?? this.preferredThemeMode,
      preferredViewType: preferredViewType ?? this.preferredViewType,
    );
  }
}
