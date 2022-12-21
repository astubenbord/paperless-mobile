import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:paperless_mobile/features/settings/model/application_settings_state.dart';
import 'package:paperless_mobile/features/settings/model/view_type.dart';

class ApplicationSettingsCubit extends HydratedCubit<ApplicationSettingsState> {
  ApplicationSettingsCubit() : super(ApplicationSettingsState.defaultSettings);

  Future<void> setLocale(String? localeSubtag) async {
    final updatedSettings = state.copyWith(preferredLocaleSubtag: localeSubtag);
    _updateSettings(updatedSettings);
  }

  Future<void> setIsBiometricAuthenticationEnabled(bool isEnabled) async {
    final updatedSettings =
        state.copyWith(isLocalAuthenticationEnabled: isEnabled);
    _updateSettings(updatedSettings);
  }

  Future<void> setThemeMode(ThemeMode? selectedMode) async {
    final updatedSettings = state.copyWith(preferredThemeMode: selectedMode);
    _updateSettings(updatedSettings);
  }

  Future<void> setViewType(ViewType viewType) async {
    final updatedSettings = state.copyWith(preferredViewType: viewType);
    _updateSettings(updatedSettings);
  }

  Future<void> _updateSettings(ApplicationSettingsState settings) async {
    emit(settings);
  }

  @override
  Future<void> clear() async {
    await super.clear();
    emit(ApplicationSettingsState.defaultSettings);
  }

  @override
  ApplicationSettingsState? fromJson(Map<String, dynamic> json) =>
      ApplicationSettingsState.fromJson(json);

  @override
  Map<String, dynamic>? toJson(ApplicationSettingsState state) =>
      state.toJson();
}
