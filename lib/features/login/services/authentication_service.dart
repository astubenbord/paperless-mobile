import 'package:local_auth/local_auth.dart';

class LocalAuthenticationService {
  final LocalAuthentication localAuthentication;

  LocalAuthenticationService(this.localAuthentication);

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
