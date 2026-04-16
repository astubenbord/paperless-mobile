import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/core/widgets/app_logs_footer_widget.dart';
import 'package:paperless_mobile/features/login/authenticate_user/cubit/authenticate_user_cubit.dart';
import 'package:paperless_mobile/features/login/authenticate_user/model/authentication_credentials.dart';
import 'package:paperless_mobile/features/login/helper/guard_unsupported_api_version.dart';
import 'package:paperless_mobile/features/login/model/client_certificate.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/helpers/message_helpers.dart';
import 'package:paperless_mobile/routing/routes/auth_route.dart';
import 'package:pinput/pinput.dart';

class OtpInputPage extends StatefulWidget {
  final String serverUrl;
  final AuthenticationCredentials credentials;

  final ClientCertificate? clientCertificate;
  const OtpInputPage({
    super.key,
    required this.serverUrl,
    required this.credentials,
    this.clientCertificate,
  });

  @override
  State<OtpInputPage> createState() => _OtpInputPageState();
}

class _OtpInputPageState extends State<OtpInputPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      height: 64,
      width: 44,
      textStyle: Theme.of(context).textTheme.titleMedium,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(32),
          bottom: Radius.circular(32),
        ),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    );

    return BlocListener<AuthenticateUserCubit, AuthenticateUserState>(
      listener: (context, state) async {
        switch (state) {
          case AuthenticateUserError error:
            if (error.nonFieldError != null) {
              showSnackBar(context, error.nonFieldError!);
            } else {
              showGenericError(context, error.genericError);
            }
            _controller.clear();
            _focusNode.requestFocus();
            break;
          case AuthenticateUserSuccess state:
            final wasHandled = await guardUnsupportedApiVersion(
              context,
              state.apiVersion,
            );
            if (!wasHandled && context.mounted) {
              AddUserRoute(
                serverUrl: state.serverUrl,
                $extra: AddUserRouteExtra(
                  token: state.token,
                  additionalHeaders: state.additionalHeaders,
                  clientCertificate: state.clientCertificate,
                ),
              ).go(context);
            }
            break;
          default:
            break;
        }
      },
      child: Scaffold(
        persistentFooterButtons: [AppLogsFooterWidget().padded()],
        persistentFooterAlignment: AlignmentDirectional.center,
        persistentFooterDecoration: BoxDecoration(),
        appBar: AppBar(),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          spacing: 16,
          children: [
            Text(
              S.of(context)!.mfaFormFieldHint,
              style: Theme.of(context).textTheme.labelLarge,
              textAlign: TextAlign.center,
            ),
            AutofillGroup(
              child: Pinput(
                focusNode: _focusNode,
                controller: _controller,
                autofocus: true,
                showCursor: false,
                length: 6,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return S.of(context)!.mfaCodeRequiredValidationMessage;
                  }
                  if (value.length != 6) {
                    return S.of(context)!.mfaCodeInvalidLengthValidationMessage;
                  }
                  return null;
                },
                focusedPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration?.copyWith(
                    color: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  textStyle: defaultPinTheme.textStyle?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                defaultPinTheme: defaultPinTheme,
                onCompleted: (value) {
                  _onSubmit(value);
                },
              ),
            ),

            BlocBuilder<AuthenticateUserCubit, AuthenticateUserState>(
              builder: (context, state) {
                if (state is AuthenticateUserChecking) {
                  return CircularProgressIndicator();
                }
                return SizedBox.shrink();
              },
            ),
          ],
        ).padded(16),
      ),
    );
  }

  void _onSubmit(String code) {
    context.read<AuthenticateUserCubit>().login(
      serverUrl: widget.serverUrl,
      credentials: widget.credentials,
      otp: code,
      clientCertificate: widget.clientCertificate,
    );
  }
}
