import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/global/constants.dart';
import 'package:paperless_mobile/core/model/server_message_exception.dart';
import 'package:paperless_mobile/core/model/info_message_exception.dart';
import 'package:paperless_mobile/core/service/connectivity_status_service.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/core/model/client_certificate.dart';
import 'package:paperless_mobile/features/login/model/login_form_credentials.dart';
import 'package:paperless_mobile/core/model/reachability_status.dart';
import 'package:paperless_mobile/features/login/view/widgets/form_fields/client_certificate_form_field.dart';
import 'package:paperless_mobile/features/login/view/widgets/form_fields/server_address_form_field.dart';
import 'package:paperless_mobile/features/login/view/widgets/form_fields/user_credentials_form_field.dart';
import 'package:paperless_mobile/generated/assets.gen.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/core/util/message_helpers.dart';
import 'package:paperless_mobile/routing/routes/app_logs_route.dart';

class AddAccountPage extends StatefulWidget {
  final FutureOr<void> Function(
    BuildContext context,
    String username,
    String password,
    String serverUrl,
    ClientCertificate? clientCertificate,
  ) onSubmit;

  final String? initialServerUrl;
  final String? initialUsername;
  final String? initialPassword;
  final ClientCertificate? initialClientCertificate;

  final String submitText;
  final String titleText;
  final bool showLocalAccounts;

  final Widget? bottomLeftButton;

  const AddAccountPage({
    super.key,
    required this.onSubmit,
    required this.submitText,
    required this.titleText,
    this.showLocalAccounts = false,
    this.initialServerUrl,
    this.initialUsername,
    this.initialPassword,
    this.initialClientCertificate,
    this.bottomLeftButton,
  });

  @override
  State<AddAccountPage> createState() => _AddAccountPageState();
}

class _AddAccountPageState extends State<AddAccountPage> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isCheckingConnection = false;
  ReachabilityStatus _reachabilityStatus = ReachabilityStatus.unknown;
  final _pageController = PageController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(widget.titleText),
      ),
      body: FormBuilder(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Assets.logos.paperlessLogoGreenPng.image(
                width: 150,
                height: 150,
              ),
              Text(
                'Paperless Mobile',
                style: Theme.of(context).textTheme.displaySmall,
              ).padded(),
              SizedBox(height: 24),
              Expanded(
                child: PageView(
                  physics: NeverScrollableScrollPhysics(),
                  controller: _pageController,
                  allowImplicitScrolling: false,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        ServerAddressFormField(
                          onChanged: (value) {
                            setState(() {
                              _reachabilityStatus = ReachabilityStatus.unknown;
                            });
                          },
                        ).paddedSymmetrically(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        ClientCertificateFormField(
                          initialBytes: widget.initialClientCertificate?.bytes,
                          initialPassphrase:
                              widget.initialClientCertificate?.passphrase,
                        ).padded(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            //TODO: Move additional headers and client cert to separate page
                            // IconButton.filledTonal(
                            //   onPressed: () {
                            //     Navigator.of(context).push(
                            //       MaterialPageRoute(builder: (context) {
                            //         return LoginSettingsPage();
                            //       }),
                            //     );
                            //   },
                            //   icon: Icon(Icons.settings),
                            // ),
                            SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: () async {
                                final status = await _updateReachability();
                                if (status == ReachabilityStatus.reachable) {
                                  Future.delayed(1.seconds, () {
                                    _pageController.nextPage(
                                      duration: Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  });
                                }
                              },
                              icon: _isCheckingConnection
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSecondary,
                                      ),
                                    )
                                  : _reachabilityStatus ==
                                          ReachabilityStatus.reachable
                                      ? Icon(Icons.done)
                                      : Icon(Icons.arrow_forward),
                              label: Text(S.of(context)!.continueLabel),
                            ),
                          ],
                        ).paddedSymmetrically(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        _buildStatusIndicator().padded(),
                      ],
                    ),
                    Column(
                      children: [
                        UserCredentialsFormField(
                          formKey: _formKey,
                          initialUsername: widget.initialUsername,
                          initialPassword: widget.initialPassword,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                _pageController.previousPage(
                                  duration: Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              icon: Icon(Icons.arrow_back),
                              label: Text(S.of(context)!.edit),
                            ),
                            FilledButton(
                              onPressed: () {
                                _onSubmit();
                              },
                              child: Text(S.of(context)!.signIn),
                            ),
                          ],
                        ).padded(),
                        Text(
                          S.of(context)!.loginRequiredPermissionsHint,
                          style: Theme.of(context).textTheme.bodySmall?.apply(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withAlpha(153),
                              ),
                        ).padded(16),
                      ],
                    ),
                  ],
                ),
              ),
              Text.rich(
                TextSpan(
                  style: Theme.of(context).textTheme.labelLarge,
                  children: [
                    TextSpan(text: S.of(context)!.version(packageInfo.version)),
                    WidgetSpan(child: SizedBox(width: 24)),
                    TextSpan(
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary),
                      text: S.of(context)!.appLogs(''),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          AppLogsRoute().push(context);
                        },
                    ),
                  ],
                ),
              ).padded(),
            ],
          ),
        ),
      ),
    );
  }

  Future<ReachabilityStatus> _updateReachability([String? address]) async {
    setState(() {
      _isCheckingConnection = true;
    });
    final selectedCertificate =
        _formKey.currentState?.getRawValue<ClientCertificate>(
      ClientCertificateFormField.fkClientCertificate,
    );
    final status = await context
        .read<ConnectivityStatusService>()
        .isPaperlessServerReachable(
          address ??
              _formKey.currentState!
                  .getRawValue(ServerAddressFormField.fkServerAddress),
          selectedCertificate,
        );
    setState(() {
      _isCheckingConnection = false;
      _reachabilityStatus = status;
    });
    return status;
  }

  Widget _buildStatusIndicator() {
    Widget buildIconText(
      IconData icon,
      String text, [
      Color? color,
    ]) {
      return ListTile(
        title: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
        ),
        leading: Icon(
          icon,
          color: color,
        ),
      );
    }

    Color errorColor = Theme.of(context).colorScheme.error;
    switch (_reachabilityStatus) {
      case ReachabilityStatus.notReachable:
        return buildIconText(
          Icons.close,
          S.of(context)!.couldNotEstablishConnectionToTheServer,
          errorColor,
        );
      case ReachabilityStatus.unknownHost:
        return buildIconText(
          Icons.close,
          S.of(context)!.hostCouldNotBeResolved,
          errorColor,
        );
      case ReachabilityStatus.missingClientCertificate:
        return buildIconText(
          Icons.close,
          S.of(context)!.loginPageReachabilityMissingClientCertificateText,
          errorColor,
        );
      case ReachabilityStatus.invalidClientCertificateConfiguration:
        return buildIconText(
          Icons.close,
          S.of(context)!.incorrectOrMissingCertificatePassphrase,
          errorColor,
        );
      case ReachabilityStatus.connectionTimeout:
        return buildIconText(
          Icons.close,
          S.of(context)!.connectionTimedOut,
          errorColor,
        );
      default:
        return const ListTile();
    }
  }

  Future<void> _onSubmit() async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final form = _formKey.currentState!.value;
      final clientCertFormModel =
          form[ClientCertificateFormField.fkClientCertificate]
              as ClientCertificate?;

      final credentials =
          form[UserCredentialsFormField.fkCredentials] as LoginFormCredentials;
      try {
        await widget.onSubmit(
          context,
          credentials.username!,
          credentials.password!,
          form[ServerAddressFormField.fkServerAddress],
          clientCertFormModel,
        );
      } on PaperlessApiException catch (error) {
        if (mounted) showErrorMessage(context, error);
      } on ServerMessageException catch (error) {
        if (mounted) showLocalizedError(context, error.message);
      } on InfoMessageException catch (error) {
        if (mounted) showInfoMessage(context, error);
      } catch (error) {
        if (mounted) showGenericError(context, error);
      }
    }
  }
}
