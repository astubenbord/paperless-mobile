import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/core/store/local_vault.dart';
import 'package:paperless_mobile/features/settings/model/application_settings_state.dart';
import 'package:injectable/injectable.dart';
import 'package:paperless_mobile/features/settings/model/view_type.dart';

@prod
@test
@lazySingleton
class ApplicationSettingsCubit extends Cubit<ApplicationSettingsState> {
  final LocalVault localVault;

  ApplicationSettingsCubit(this.localVault)
      : super(ApplicationSettingsState.defaultSettings);

  Future<void> initialize() async {
    final settings = (await localVault.loadApplicationSettings()) ??
        ApplicationSettingsState.defaultSettings;
    emit(settings);
  }

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
    await localVault.storeApplicationSettings(settings);
    emit(settings);
  }

  void clear() {
    emit(ApplicationSettingsState.defaultSettings);
  }
}
