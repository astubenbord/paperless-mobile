import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/database/hive/hive_extensions.dart';
import 'package:paperless_mobile/core/model/info_message_exception.dart';
import 'package:paperless_mobile/features/login/cubit/authentication_cubit.dart';
import 'package:paperless_mobile/core/model/client_certificate.dart';
import 'package:paperless_mobile/features/login/model/login_form_credentials.dart';
import 'package:paperless_mobile/features/login/view/add_account_page.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/helpers/message_helpers.dart';
import 'package:paperless_mobile/routing/routes/login_route.dart';

class LoginPage extends StatelessWidget {
  final String? initialServerUrl;
  final String? initialUsername;
  final String? initialPassword;
  final ClientCertificate? initialClientCertificate;

  const LoginPage({
    super.key,
    this.initialServerUrl,
    this.initialUsername,
    this.initialPassword,
    this.initialClientCertificate,
  });

  @override
  Widget build(BuildContext context) {
    return AddAccountPage(
      titleText: S.of(context)!.connectToPaperless,
      submitText: S.of(context)!.signIn,
      onSubmit: _onLogin,
      showLocalAccounts: true,
      initialServerUrl: initialServerUrl,
      initialUsername: initialUsername,
      initialPassword: initialPassword,
      initialClientCertificate: initialClientCertificate,
      bottomLeftButton: Hive.localUserAccountBox.isNotEmpty
          ? TextButton(
              child: Text(S.of(context)!.logInToExistingAccount),
              onPressed: () {
                const LoginToExistingAccountRoute().go(context);
              },
            )
          : null,
    );
  }

  void _onLogin(
    BuildContext context,
    String username,
    String password,
    String serverUrl,
    ClientCertificate? clientCertificate,
  ) async {
    try {
      await context.read<AuthenticationCubit>().login(
            credentials: LoginFormCredentials(
              username: username,
              password: password,
            ),
            serverUrl: serverUrl,
            clientCertificate: clientCertificate,
          );

      // DocumentsRoute().go(context);
    } on PaperlessApiException catch (error, stackTrace) {
      if (context.mounted) showErrorMessage(context, error, stackTrace);
    } on PaperlessFormValidationException catch (exception, stackTrace) {
      if (exception.hasUnspecificErrorMessage()) {
        if (context.mounted) {
          showLocalizedError(context, exception.unspecificErrorMessage()!);
        }
      } else {
        if (context.mounted) {
          showGenericError(
            context,
            exception.validationMessages.values.first,
            stackTrace,
          ); //TODO: Check if we can show error message directly on field here.
        }
      }
    } on InfoMessageException catch (error) {
      if (context.mounted) showInfoMessage(context, error);
    } catch (unknownError, stackTrace) {
      if (context.mounted) {
        showGenericError(context, unknownError.toString(), stackTrace);
      }
    }
  }
}
