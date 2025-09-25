import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/features/login/cubit/authentication_cubit.dart';
import 'package:paperless_mobile/features/login/model/client_certificate.dart';
import 'package:paperless_mobile/features/login/view/widgets/totp_bottom_sheet.dart';
import 'package:paperless_mobile/features/logging/data/logger.dart';
import 'package:paperless_api/paperless_api.dart';

class TwoFactorController {
  TwoFactorController._();
  static final TwoFactorController instance = TwoFactorController._();

  Future<bool> handleMfaFlow(
    BuildContext context, {
    required String username,
    required String password,
    required String serverUrl,
    ClientCertificate? clientCertificate,
  }) async {
    logger.fd(
      "TwoFactorController.handleMfaFlow started for user: $username",
      className: 'TwoFactorController',
      methodName: 'handleMfaFlow',
    );

    final bool success = await showTotpBottomSheet(
      context,
      onVerify: (code) async {
        logger.fd(
          "TwoFactorController verifying TOTP code (length: ${code.length})",
          className: 'TwoFactorController',
          methodName: 'handleMfaFlow',
        );

        try {
          // Use dedicated MFA path on the cubit
          await context.read<AuthenticationCubit>().verifyMfaCode(code);
          logger.fd(
            "TOTP verification successful",
            className: 'TwoFactorController',
            methodName: 'handleMfaFlow',
          );
          return null; // no error -> success
        } on PaperlessFormValidationException catch (e) {
          final errorMessage = e.unspecificErrorMessage() ??
              (e.validationMessages.isNotEmpty
                  ? e.validationMessages.values.first
                  : 'Invalid code');
          logger.fw(
            "TOTP verification failed: $errorMessage",
            className: 'TwoFactorController',
            methodName: 'handleMfaFlow',
          );
          // return specific message to display inline
          return errorMessage;
        }
      },
    );

    // If user canceled, reset authentication state to go back to login
    if (!success) {
      logger.fd(
        "User canceled MFA, calling cancelMfa to reset state",
        className: 'TwoFactorController',
        methodName: 'handleMfaFlow',
      );
      await context.read<AuthenticationCubit>().cancelMfa();
    }

    logger.fd(
      "TwoFactorController.handleMfaFlow completed with success: $success",
      className: 'TwoFactorController',
      methodName: 'handleMfaFlow',
    );

    return success;
  }
}
