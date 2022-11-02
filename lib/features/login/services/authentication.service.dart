import 'dart:convert';

import 'package:paperless_mobile/core/model/error_message.dart';
import 'package:paperless_mobile/core/store/local_vault.dart';
import 'package:http/http.dart';
import 'package:injectable/injectable.dart';
import 'package:local_auth/local_auth.dart';

@singleton
class AuthenticationService {
  final BaseClient httpClient;
  final LocalVault localStore;
  final LocalAuthentication localAuthentication;

  AuthenticationService(
    this.localStore,
    this.localAuthentication,
    @Named("timeoutClient") this.httpClient,
  );

  ///
  /// Returns the authentication token.
  ///
  Future<String> login({
    required String username,
    required String password,
    required String serverUrl,
  }) async {
    final response = await httpClient.post(
      Uri.parse("/api/token/"),
      body: {"username": username, "password": password},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['token'];
    } else if (response.statusCode == 400 &&
        response.body.toLowerCase().contains("no required certificate was sent")) {
      throw const ErrorMessage(ErrorCode.invalidClientCertificateConfiguration);
    } else {
      throw const ErrorMessage(ErrorCode.authenticationFailed);
    }
  }

  Future<bool> authenticateLocalUser(String localizedReason) async {
    if (await localAuthentication.isDeviceSupported()) {
      return await localAuthentication.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );
    }
    return false;
  }
}
