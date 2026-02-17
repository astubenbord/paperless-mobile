import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/model/info_message_exception.dart';
import 'package:paperless_mobile/features/login/cubit/authentication_cubit.dart';
import 'package:paperless_mobile/features/login/model/login_form_credentials.dart';
import 'package:paperless_mobile/features/login/view/add_account_page.dart';
import 'package:paperless_mobile/features/settings/view/dialogs/switch_account_dialog.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/core/util/message_helpers.dart';
import 'package:paperless_mobile/routing/navigation_keys.dart';
import 'package:paperless_mobile/routing/routes.dart';

part 'add_account_route.g.dart';

@TypedGoRoute<AddAccountRoute>(
  path: '/add-account',
  name: R.addAccount,
)
class AddAccountRoute extends GoRouteData with $AddAccountRoute {
  const AddAccountRoute();

  static final $parentNavigatorKey = rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return NoTransitionPage(
      child: AddAccountPage(
        titleText: S.of(context)!.addAccount,
        onSubmit:
            (context, username, password, serverUrl, clientCertificate) async {
          try {
            final userId = await context.read<AuthenticationCubit>().addAccount(
                  credentials: LoginFormCredentials(
                    username: username,
                    password: password,
                  ),
                  clientCertificate: clientCertificate,
                  serverUrl: serverUrl,
                  enableBiometricAuthentication: false,
                  locale: Intl.getCurrentLocale(),
                );
            if (!context.mounted) return;
            final shouldSwitch = await showDialog<bool>(
                  context: context,
                  builder: (context) => const SwitchAccountDialog(),
                ) ??
                false;
            if (shouldSwitch) {
              if (!context.mounted) return;
              await context.read<AuthenticationCubit>().switchAccount(userId);
            } else {
              if (context.mounted) context.pop();
            }
          } on PaperlessApiException catch (error, stackTrace) {
            if (context.mounted) showErrorMessage(context, error, stackTrace);
            // context.pop();
          } on PaperlessFormValidationException catch (exception, stackTrace) {
            if (exception.hasUnspecificErrorMessage()) {
              if (context.mounted) {
                showLocalizedError(
                    context, exception.unspecificErrorMessage()!);
              }
              // context.pop();
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
            // context.pop();
          } catch (unknownError, stackTrace) {
            if (context.mounted) {
              showGenericError(context, unknownError.toString(), stackTrace);
            }
            // context.pop();
          }
        },
        submitText: S.of(context)!.addAccount,
      ),
    );
  }
}
