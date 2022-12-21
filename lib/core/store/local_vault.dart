import 'dart:convert';

import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:paperless_mobile/core/type/types.dart';
import 'package:paperless_mobile/features/login/model/authentication_information.dart';
import 'package:paperless_mobile/features/login/model/client_certificate.dart';
import 'package:paperless_mobile/features/settings/model/application_settings_state.dart';

abstract class LocalVault {
  Future<void> storeAuthenticationInformation(AuthenticationInformation auth);
  Future<AuthenticationInformation?> loadAuthenticationInformation();
  Future<ClientCertificate?> loadCertificate();
  Future<bool> storeApplicationSettings(ApplicationSettingsState settings);
  Future<ApplicationSettingsState?> loadApplicationSettings();
  Future<void> clear();
}

class LocalVaultImpl implements LocalVault {
  static const applicationSettingsKey = "applicationSettings";
  static const authenticationKey = "authentication";

  final EncryptedSharedPreferences sharedPreferences;

  LocalVaultImpl(this.sharedPreferences);

  @override
  Future<void> storeAuthenticationInformation(
    AuthenticationInformation auth,
  ) async {
    await sharedPreferences.setString(
      authenticationKey,
      jsonEncode(auth.toJson()),
    );
  }

  @override
  Future<AuthenticationInformation?> loadAuthenticationInformation() async {
    if ((await sharedPreferences.getString(authenticationKey)).isEmpty) {
      return null;
    }
    return AuthenticationInformation.fromJson(
      jsonDecode(await sharedPreferences.getString(authenticationKey)),
    );
  }

  @override
  Future<ClientCertificate?> loadCertificate() async {
    return loadAuthenticationInformation()
        .then((value) => value?.clientCertificate);
  }

  @override
  Future<bool> storeApplicationSettings(ApplicationSettingsState settings) {
    return sharedPreferences.setString(
      applicationSettingsKey,
      jsonEncode(settings.toJson()),
    );
  }

  @override
  Future<ApplicationSettingsState?> loadApplicationSettings() async {
    final settings = await sharedPreferences.getString(applicationSettingsKey);
    if (settings.isEmpty) {
      return null;
    }
    return compute(
      ApplicationSettingsState.fromJson,
      jsonDecode(settings) as JSON,
    );
  }

  @override
  Future<void> clear() {
    return sharedPreferences.clear();
  }
}
