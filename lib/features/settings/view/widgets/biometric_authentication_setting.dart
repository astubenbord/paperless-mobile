import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/features/login/services/authentication_service.dart';
import 'package:paperless_mobile/features/settings/view/widgets/user_settings_builder.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class BiometricAuthenticationSetting extends StatelessWidget {
  const BiometricAuthenticationSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return UserAccountBuilder(
      builder: (context, account) {
        if (account == null) {
          return const SizedBox.shrink();
        }
        return SwitchListTile(
          value: account.settings.isBiometricAuthenticationEnabled,
          title: Text(S.of(context)!.biometricAuthentication),
          subtitle: Text(S.of(context)!.authenticateOnAppStart),
          onChanged: (val) async {
            final String localizedReason =
                S.of(context)!.authenticateToToggleBiometricAuthentication(
                      val ? 'enable' : 'disable',
                    );

            final isAuthenticated = await context
                .read<LocalAuthenticationService>()
                .authenticateLocalUser(localizedReason);
            if (isAuthenticated) {
              account.settings.isBiometricAuthenticationEnabled = val;
              await account.save();
            }
          },
        );
      },
    );
  }
}
