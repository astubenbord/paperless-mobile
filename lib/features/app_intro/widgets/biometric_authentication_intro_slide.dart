import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/di_initializer.dart';
import 'package:paperless_mobile/features/login/services/authentication.service.dart';
import 'package:paperless_mobile/features/settings/bloc/application_settings_cubit.dart';
import 'package:paperless_mobile/features/settings/model/application_settings_state.dart';
import 'package:paperless_mobile/util.dart';

class BiometricAuthenticationIntroSlide extends StatefulWidget {
  const BiometricAuthenticationIntroSlide({
    Key? key,
  }) : super(key: key);

  @override
  State<BiometricAuthenticationIntroSlide> createState() =>
      _BiometricAuthenticationIntroSlideState();
}

class _BiometricAuthenticationIntroSlideState
    extends State<BiometricAuthenticationIntroSlide> {
  @override
  Widget build(BuildContext context) {
    //TODO: INTL
    return BlocBuilder<ApplicationSettingsCubit, ApplicationSettingsState>(
      builder: (context, settings) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Configure Biometric Authentication",
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            Text(
              "It is highly recommended to additionally secure your local data. Do you want to enable biometric authentication?",
              textAlign: TextAlign.center,
            ),
            Column(
              children: [
                const Icon(
                  Icons.fingerprint,
                  size: 48,
                ),
                const SizedBox(
                  height: 32,
                ),
                Builder(builder: (context) {
                  if (settings.isLocalAuthenticationEnabled) {
                    return ElevatedButton.icon(
                      icon: Icon(
                        Icons.done,
                        color: Colors.green,
                      ),
                      label: Text("Enabled"),
                      onPressed: null,
                    );
                  }
                  return ElevatedButton(
                    child: Text("Enable"),
                    onPressed: () {
                      final settings =
                          BlocProvider.of<ApplicationSettingsCubit>(context)
                              .state;
                      getIt<AuthenticationService>()
                          .authenticateLocalUser(
                              "Please authenticate to secure Paperless Mobile")
                          .then((isEnabled) {
                        if (!isEnabled) {
                          showSnackBar(context,
                              "Could not set up biometric authentication. Please try again or skip for now.");
                          return;
                        }
                        BlocProvider.of<ApplicationSettingsCubit>(context)
                            .setIsBiometricAuthenticationEnabled(true);
                      });
                    },
                  );
                }),
              ],
            ),
          ],
        );
      },
    );
  }
}
