import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/database/hive/hive_extensions.dart';
import 'package:paperless_mobile/core/model/info_message_exception.dart';
import 'package:paperless_mobile/features/login/cubit/authentication_cubit.dart';
import 'package:paperless_mobile/features/login/model/client_certificate.dart';
import 'package:paperless_mobile/features/login/model/login_form_credentials.dart';
import 'package:paperless_mobile/features/login/view/add_account_page.dart';
import 'package:paperless_mobile/features/login/view/widgets/totp_dialog.dart';
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
      checkForExistingUser: false,
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

  Future<void> _onLogin(
    BuildContext context,
    LoginFormCredentials credentials,
    String serverUrl,
    ClientCertificate? clientCertificate,
  ) async {
    try {
      await context.read<AuthenticationCubit>().login(
            credentials: credentials,
            serverUrl: serverUrl,
            clientCertificate: clientCertificate,
          );

      // DocumentsRoute().go(context);
    } on PaperlessMfaRequiredException {
      // Show TOTP dialog
      if (!context.mounted) return;

      final totpCode = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => TotpDialog(
          onSubmit: (code) => Navigator.pop(context, code),
        ),
      );

      if (totpCode != null && context.mounted) {
        // Retry login with TOTP code
        final updatedCredentials = credentials.copyWith(totpCode: totpCode);
        // Reset to unauthenticated state so we can try logging in again
        context.read<AuthenticationCubit>().cancelLogin();
        await _onLogin(
            context, updatedCredentials, serverUrl, clientCertificate);
      } else {
        if (context.mounted) {
          context.read<AuthenticationCubit>().cancelLogin();
        }
      }
    } on PaperlessApiException catch (error, stackTrace) {
      if (context.mounted) {
        // Reset to unauthenticated state to dismiss authenticating screen
        context.read<AuthenticationCubit>().cancelLogin();

        if (error.code == ErrorCode.invalidMfaCode) {
          showErrorMessage(context, error, stackTrace);
        } else {
          showErrorMessage(context, error, stackTrace);
        }
      }
    } on PaperlessFormValidationException catch (exception, stackTrace) {
      if (context.mounted) {
        // Reset to unauthenticated state to dismiss authenticating screen
        context.read<AuthenticationCubit>().cancelLogin();
      }
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
      if (context.mounted) {
        context.read<AuthenticationCubit>().cancelLogin();
        showInfoMessage(context, error);
      }
    } catch (unknownError, stackTrace) {
      if (context.mounted) {
        context.read<AuthenticationCubit>().cancelLogin();
        showGenericError(context, unknownError.toString(), stackTrace);
      }
    }
  }
}
