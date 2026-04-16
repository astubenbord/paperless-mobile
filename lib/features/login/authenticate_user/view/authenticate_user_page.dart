import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/core/widgets/app_logs_footer_widget.dart';
import 'package:paperless_mobile/features/login/authenticate_user/cubit/authenticate_user_cubit.dart';
import 'package:paperless_mobile/features/login/authenticate_user/model/authentication_credentials.dart';
import 'package:paperless_mobile/features/login/helper/guard_unsupported_api_version.dart';
import 'package:paperless_mobile/features/login/model/client_certificate.dart';
import 'package:paperless_mobile/features/login/server_connection/model/header_entry.dart';
import 'package:paperless_mobile/features/login/view/widgets/form_fields/authentication_credentials_form_field.dart';
import 'package:paperless_mobile/generated/assets.gen.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/helpers/message_helpers.dart';
import 'package:paperless_mobile/routing/routes/auth_route.dart';

class AuthenticateUserPage extends StatefulWidget {
  final String serverUrl;
  final ClientCertificate? clientCertificate;
  final List<HeaderEntry>? additionalHeaders;
  final AuthenticationCredentials? initialCredentials;

  const AuthenticateUserPage({
    super.key,
    required this.serverUrl,
    this.initialCredentials,
    this.clientCertificate,
    this.additionalHeaders,
  });
  @override
  State<AuthenticateUserPage> createState() => _AuthenticateUserPageState();
}

class _AuthenticateUserPageState extends State<AuthenticateUserPage> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthenticateUserCubit, AuthenticateUserState>(
      listener: (context, state) async {
        switch (state) {
          case AuthenticateUserError error:
            if (error.nonFieldError != null) {
              showLocalizedError(context, error.nonFieldError!);
              break;
            }
            showGenericError(context, error.genericError);
            break;
          case AuthenticateUserSuccess(
            :final serverUrl,
            :final clientCertificate,
            :final token,
            :final additionalHeaders,
          ):
            final wasHandled = await guardUnsupportedApiVersion(
              context,
              state.apiVersion,
            );
            if (!wasHandled && context.mounted) {
              AddUserRoute(
                serverUrl: serverUrl,
                $extra: AddUserRouteExtra(
                  token: token,
                  additionalHeaders: additionalHeaders,
                  clientCertificate: clientCertificate,
                ),
              ).replace(context);
            }
            break;
          case AuthenticateUserOtpRequired(
            :final serverUrl,
            :final credentials,
            :final clientCertificate,
          ):
            OtpRoute(
              serverUrl: serverUrl,
              $extra: OtpRouteExtra(
                credentials: credentials,
                clientCertificate: clientCertificate,
              ),
            ).push(context);
            break;
          default:
            break;
        }
      },
      child: Scaffold(
        persistentFooterButtons: [AppLogsFooterWidget().padded()],
        persistentFooterAlignment: AlignmentDirectional.center,
        persistentFooterDecoration: BoxDecoration(),
        resizeToAvoidBottomInset: false,
        appBar: AppBar(title: Text(S.of(context)!.connectToPaperless)),
        body: FormBuilder(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Assets.logos.paperlessLogoGreenPng.image(width: 150, height: 150),
              Text(
                'Paperless Mobile',
                style: Theme.of(context).textTheme.displaySmall,
              ).padded(),
              SizedBox(height: 24),
              Expanded(
                child: Column(
                  children: [
                    AuthenticationCredentialsFormField(
                      formKey: _formKey,
                      onSubmitted: _onSubmit,
                      initialUsername: widget.initialCredentials?.mapOrNull(
                        password: (value) => value.username,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      spacing: 8,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            context.pop();
                          },
                          icon: Icon(Icons.arrow_back),
                          label: Text(S.of(context)!.edit),
                        ),
                        _buildSubmitButton(),
                      ],
                    ).padded(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return BlocBuilder<AuthenticateUserCubit, AuthenticateUserState>(
      builder: (context, state) {
        return switch (state) {
          AuthenticateUserChecking() => FilledButton.icon(
            onPressed: null,
            label: Text(S.of(context)!.signIn),
            icon: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(),
            ),
          ),
          _ => FilledButton(
            onPressed: _onSubmit,
            child: Text(S.of(context)!.signIn),
          ),
        };
      },
    );
  }

  Future<void> _onSubmit() async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final form = _formKey.currentState!.value;
      final credentials =
          form[AuthenticationCredentialsFormField.fkCredentials]
              as AuthenticationCredentials;

      context.read<AuthenticateUserCubit>().login(
        serverUrl: widget.serverUrl,
        // We can safely enforce non-null here since the validation already took care of it
        credentials: credentials,
        clientCertificate: widget.clientCertificate,
        additionalHeaders: widget.additionalHeaders,
      );
    }
  }
}
