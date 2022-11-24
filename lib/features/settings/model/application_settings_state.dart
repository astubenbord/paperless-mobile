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
    showInboxOnStartup: true,
  );

  static const isLocalAuthenticationEnabledKey = "isLocalAuthenticationEnabled";
  static const preferredLocaleSubtagKey = "localeSubtag";
  static const preferredThemeModeKey = "preferredThemeModeKey";
  static const preferredViewTypeKey = 'preferredViewType';
  static const showInboxOnStartupKey = 'showinboxOnStartup';

  final bool isLocalAuthenticationEnabled;
  final String preferredLocaleSubtag;
  final ThemeMode preferredThemeMode;
  final ViewType preferredViewType;
  final bool showInboxOnStartup;

  ApplicationSettingsState({
    required this.preferredLocaleSubtag,
    required this.preferredThemeMode,
    required this.isLocalAuthenticationEnabled,
    required this.preferredViewType,
    required this.showInboxOnStartup,
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
      : isLocalAuthenticationEnabled = json[isLocalAuthenticationEnabledKey] ??
            defaultSettings.isLocalAuthenticationEnabled,
        preferredLocaleSubtag = json[preferredLocaleSubtagKey] ??
            defaultSettings.preferredLocaleSubtag,
        preferredThemeMode = json.containsKey(preferredThemeModeKey)
            ? ThemeMode.values.byName(json[preferredThemeModeKey])
            : defaultSettings.preferredThemeMode,
        preferredViewType = json.containsKey(preferredViewTypeKey)
            ? ViewType.values.byName(json[preferredViewTypeKey])
            : defaultSettings.preferredViewType,
        showInboxOnStartup =
            json[showInboxOnStartupKey] ?? defaultSettings.showInboxOnStartup;

  ApplicationSettingsState copyWith({
    bool? isLocalAuthenticationEnabled,
    String? preferredLocaleSubtag,
    ThemeMode? preferredThemeMode,
    ViewType? preferredViewType,
    bool? showInboxOnStartup,
  }) {
    return ApplicationSettingsState(
      isLocalAuthenticationEnabled:
          isLocalAuthenticationEnabled ?? this.isLocalAuthenticationEnabled,
      preferredLocaleSubtag:
          preferredLocaleSubtag ?? this.preferredLocaleSubtag,
      preferredThemeMode: preferredThemeMode ?? this.preferredThemeMode,
      preferredViewType: preferredViewType ?? this.preferredViewType,
      showInboxOnStartup: showInboxOnStartup ?? this.showInboxOnStartup,
    );
  }
}
