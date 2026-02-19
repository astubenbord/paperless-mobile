import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:paperless_mobile/core/logging/logger.dart';

class LocalAuthenticationService {
  final LocalAuthentication localAuthentication;

  LocalAuthenticationService(
    this.localAuthentication,
  );

  Future<bool> authenticateLocalUser(String localizedReason) async {
    try {
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
    } on PlatformException catch (e) {
      logger.fw(
        'Biometric authentication failed: ${e.code} - ${e.message}',
        className: 'LocalAuthenticationService',
        methodName: 'authenticateLocalUser',
      );
    }
    return false;
  }
}
