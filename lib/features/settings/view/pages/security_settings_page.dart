import 'package:flutter/material.dart';
import 'package:paperless_mobile/features/settings/view/widgets/biometric_authentication_setting.dart';
import 'package:paperless_mobile/generated/l10n.dart';

class SecuritySettingsPage extends StatelessWidget {
  const SecuritySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).settingsPageSecuritySettingsLabel)),
      body: ListView(
        children: const [
          BiometricAuthenticationSetting(),
        ],
      ),
    );
  }
}
