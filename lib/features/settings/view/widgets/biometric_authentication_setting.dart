import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/di_initializer.dart';
import 'package:paperless_mobile/features/login/services/authentication.service.dart';
import 'package:paperless_mobile/features/settings/bloc/application_settings_cubit.dart';
import 'package:paperless_mobile/features/settings/model/application_settings_state.dart';
import 'package:paperless_mobile/generated/l10n.dart';

class BiometricAuthenticationSetting extends StatelessWidget {
  const BiometricAuthenticationSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ApplicationSettingsCubit, ApplicationSettingsState>(
      builder: (context, settings) {
        return SwitchListTile(
          value: settings.isLocalAuthenticationEnabled,
          title: Text(S.of(context).appSettingsBiometricAuthenticationLabel),
          subtitle: Text(S.of(context).appSettingsBiometricAuthenticationDescriptionText),
          onChanged: (val) async {
            final settingsBloc = BlocProvider.of<ApplicationSettingsCubit>(context);
            final String localizedReason = val
                ? S.of(context).appSettingsEnableBiometricAuthenticationReasonText
                : S.of(context).appSettingsDisableBiometricAuthenticationReasonText;
            final changeValue =
                await getIt<AuthenticationService>().authenticateLocalUser(localizedReason);
            if (changeValue) {
              settingsBloc.setIsBiometricAuthenticationEnabled(val);
            }
          },
        );
      },
    );
  }
}
