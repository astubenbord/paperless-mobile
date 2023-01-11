import 'package:local_auth/local_auth.dart';
import 'package:paperless_mobile/core/store/local_vault.dart';

class LocalAuthenticationService {
  final LocalVault localStore;
  final LocalAuthentication localAuthentication;

  LocalAuthenticationService(
    this.localStore,
    this.localAuthentication,
  );

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
