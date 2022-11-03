import 'dart:convert';

import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';
import 'package:paperless_mobile/features/login/model/authentication_information.dart';
import 'package:paperless_mobile/features/login/model/client_certificate.dart';
import 'package:paperless_mobile/features/settings/model/application_settings_state.dart';
import 'package:injectable/injectable.dart';

@singleton
class LocalVault {
  static const applicationSettingsKey = "applicationSettings";
  static const authenticationKey = "authentication";

  final EncryptedSharedPreferences sharedPreferences;

  LocalVault(this.sharedPreferences);

  Future<void> storeAuthenticationInformation(
    AuthenticationInformation auth,
  ) async {
    await sharedPreferences.setString(
      authenticationKey,
      json.encode(auth.toJson()),
    );
  }

  Future<AuthenticationInformation?> loadAuthenticationInformation() async {
    if ((await sharedPreferences.getString(authenticationKey)).isEmpty) {
      return null;
    }
    return AuthenticationInformation.fromJson(
      json.decode(await sharedPreferences.getString(authenticationKey)),
    );
  }

  Future<ClientCertificate?> loadCertificate() async {
    return loadAuthenticationInformation()
        .then((value) => value?.clientCertificate);
  }

  Future<bool> storeApplicationSettings(ApplicationSettingsState settings) {
    return sharedPreferences.setString(
        applicationSettingsKey, json.encode(settings.toJson()));
  }

  Future<ApplicationSettingsState?> loadApplicationSettings() async {
    final settings = await sharedPreferences.getString(applicationSettingsKey);
    if (settings.isEmpty) {
      return null;
    }
    return ApplicationSettingsState.fromJson(json.decode(settings));
  }

  Future<void> clear() {
    return sharedPreferences.clear();
  }
}
