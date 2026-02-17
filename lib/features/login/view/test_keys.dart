import 'package:flutter/widgets.dart';

class TestKeys {
  TestKeys._();

  static final login = _LoginTestKeys();
}

class _LoginTestKeys {
  final serverAddressFormField = const Key('login-server-address');
  final continueButton = const Key('login-continue-button');
  final usernameFormField = const Key('login-username');
  final passwordFormField = const Key('login-password');
  final loginButton = const Key('login-login-button');
  final clientCertificateFormField = const Key('login-client-certificate');
  final clientCertificatePassphraseFormField =
      const Key('login-client-certificate-passphrase');
  final loggingInScreen = const Key('login-logging-in-screen');
}
