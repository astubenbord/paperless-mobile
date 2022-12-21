import 'dart:io';

import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:paperless_mobile/core/type/types.dart';
import 'package:paperless_mobile/features/settings/model/view_type.dart';

part 'application_settings_state.g.dart';

///
/// State holding the current application settings such as selected language, theme mode and more.
///
@JsonSerializable()
class ApplicationSettingsState {
  static final defaultSettings = ApplicationSettingsState(
    isLocalAuthenticationEnabled: false,
    preferredLocaleSubtag: Platform.localeName.split('_').first,
    preferredThemeMode: ThemeMode.system,
    preferredViewType: ViewType.list,
  );

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

  Map<String, dynamic> toJson() => _$ApplicationSettingsStateToJson(this);
  factory ApplicationSettingsState.fromJson(Map<String, dynamic> json) =>
      _$ApplicationSettingsStateFromJson(json);

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
