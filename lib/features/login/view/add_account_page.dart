import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/constants.dart';
import 'package:paperless_mobile/core/exception/server_message_exception.dart';
import 'package:paperless_mobile/core/model/info_message_exception.dart';
import 'package:paperless_mobile/core/security/android_keychain.dart';
import 'package:paperless_mobile/core/service/connectivity_status_service.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/login/cubit/authentication_cubit.dart';
import 'package:paperless_mobile/features/login/model/client_certificate.dart';
import 'package:paperless_mobile/features/login/model/login_form_credentials.dart';
import 'package:paperless_mobile/features/login/model/reachability_status.dart';
import 'package:paperless_mobile/features/login/view/widgets/form_fields/client_certificate_form_field.dart';
import 'package:paperless_mobile/features/login/view/widgets/form_fields/server_address_form_field.dart';
import 'package:paperless_mobile/features/login/view/widgets/form_fields/user_credentials_form_field.dart';
import 'package:paperless_mobile/generated/assets.gen.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/helpers/message_helpers.dart';
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
  bool _isFormSubmitted = false;

  // Guard to prevent re-prompting on the same login attempt
  bool _hasPromptedForCertificate = false;

  // Store the selected certificate from reachability check
  ClientCertificate? _selectedClientCertificate;

  final _pageController = PageController();
  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthenticationCubit, AuthenticationState>(
      listener: (context, state) async {
        // Debug logging
        debugPrint('AddAccountPage BlocListener - State received: ${state.runtimeType}');
        debugPrint('AddAccountPage BlocListener - State: $state');

        // Automatically handle client certificate requirement
        if (state is ClientCertificateRequiredState) {
          debugPrint('AddAccountPage BlocListener - ClientCertificateRequiredState detected!');
          debugPrint('AddAccountPage BlocListener - _hasPromptedForCertificate: $_hasPromptedForCertificate');

          // Guard against prompt loops - only prompt once per login attempt
          if (!_hasPromptedForCertificate) {
            _hasPromptedForCertificate = true;
            debugPrint('AddAccountPage BlocListener - Calling _handleClientCertificateRequired...');
            await _handleClientCertificateRequired(
              context,
              state.serverUrl,
              state.username,
              state.password,
            );
          } else {
            // Already prompted and still failing - show error instead of looping
            debugPrint('AddAccountPage BlocListener - Already prompted, showing error');
            if (mounted) {
              showLocalizedError(
                context,
                S.of(context)!.loginPageReachabilityMissingClientCertificateText,
              );
            }
          }
        } else if (state is AuthenticatedState) {
          // Reset the guard on successful authentication
          debugPrint('AddAccountPage BlocListener - AuthenticatedState, resetting guard');
          _hasPromptedForCertificate = false;
        }
      },
      child: Scaffold(
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
                        // Client certificate is now handled automatically when needed
                        // ClientCertificateFormField hidden from UI
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
                                } else if (status == ReachabilityStatus.missingClientCertificate) {
                                  // Automatically prompt for client certificate
                                  debugPrint('Reachability check detected missing client cert - prompting for KeyChain');
                                  if (!_hasPromptedForCertificate) {
                                    _hasPromptedForCertificate = true;
                                    final serverUrl = _formKey.currentState!
                                        .getRawValue(ServerAddressFormField.fkServerAddress);
                                    await _handleClientCertificateRequiredFromReachability(serverUrl);
                                  }
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
      ),
    );
  }

  Future<void> _handleClientCertificateRequiredFromReachability(String serverUrl) async {
    // Automatically prompt for Android KeyChain certificate selection during reachability check
    if (!AndroidKeyChain.isSupported) {
      // Non-Android platforms - show error message
      if (mounted) {
        showLocalizedError(
          context,
          S.of(context)!.loginPageReachabilityMissingClientCertificateText,
        );
      }
      return;
    }

    // Normalize URL and extract host for KeyChain picker
    final normalizedUrl = serverUrl.contains('://') ? serverUrl : 'https://$serverUrl';
    final uri = Uri.parse(normalizedUrl);
    final host = uri.host;

    debugPrint('Prompting for Android KeyChain alias for host: $host');

    // Show Android KeyChain picker
    final alias = await AndroidKeyChain.selectClientCertificateAlias(
      host: host.isNotEmpty ? host : null,
    );

    if (alias == null || alias.isEmpty) {
      // User cancelled or no cert selected
      debugPrint('User cancelled KeyChain selection or no alias selected');
      setState(() {
        _hasPromptedForCertificate = false;
      });
      return;
    }

    debugPrint('Selected KeyChain alias: $alias');

    // Create client certificate with the selected alias
    final clientCertificate = ClientCertificate(
      bytes: Uint8List(0),
      filename: 'Android KeyChain',
      androidKeyAlias: alias,
    );

    // Retry reachability check with the selected certificate
    final status = await context
        .read<ConnectivityStatusService>()
        .isPaperlessServerReachable(serverUrl, clientCertificate);

    setState(() {
      _reachabilityStatus = status;
      _hasPromptedForCertificate = false; // Reset for next attempt
      // Store the certificate for use during login
      if (status == ReachabilityStatus.reachable) {
        _selectedClientCertificate = clientCertificate;
      }
    });

    if (status == ReachabilityStatus.reachable) {
      // Success! Move to credentials page
      Future.delayed(1.seconds, () {
        if (mounted) {
          _pageController.nextPage(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  Future<void> _handleClientCertificateRequired(
    BuildContext context,
    String serverUrl,
    String username,
    String password,
  ) async {
    // Automatically prompt for Android KeyChain certificate selection
    if (!AndroidKeyChain.isSupported) {
      // Non-Android platforms - show error message
      if (mounted) {
        showLocalizedError(
          context,
          S.of(context)!.loginPageReachabilityMissingClientCertificateText,
        );
      }
      return;
    }

    // Normalize URL and extract host for KeyChain picker
    // Handle URLs without scheme (e.g., "paperless.example.com" -> "https://paperless.example.com")
    final normalizedUrl = serverUrl.contains('://') ? serverUrl : 'https://$serverUrl';
    final uri = Uri.parse(normalizedUrl);
    final host = uri.host;

    // Show Android KeyChain picker
    final alias = await AndroidKeyChain.selectClientCertificateAlias(
      host: host.isNotEmpty ? host : null,
    );

    if (alias == null || alias.isEmpty) {
      // User cancelled or no cert selected
      return;
    }

    // Create client certificate with the selected alias
    final clientCertificate = ClientCertificate(
      bytes: Uint8List(0),
      filename: 'Android KeyChain',
      androidKeyAlias: alias,
    );

    // Automatically retry login with the selected certificate
    if (mounted) {
      await context.read<AuthenticationCubit>().login(
            credentials: LoginFormCredentials(
              username: username,
              password: password,
            ),
            serverUrl: serverUrl,
            clientCertificate: clientCertificate,
          );
    }
  }

  Future<ReachabilityStatus> _updateReachability([String? address]) async {
    setState(() {
      _isCheckingConnection = true;
    });
    // Client certificate is now handled automatically when needed,
    // so we check reachability without it initially
    final status = await context
        .read<ConnectivityStatusService>()
        .isPaperlessServerReachable(
          address ??
              _formKey.currentState!
                  .getRawValue(ServerAddressFormField.fkServerAddress),
          null, // No cert on initial check
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
    setState(() {
      _isFormSubmitted = true;
      // Reset cert prompt guard for new login attempt
      _hasPromptedForCertificate = false;
    });
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final form = _formKey.currentState!.value;
      // Client certificate is now handled automatically when needed
      final credentials =
          form[UserCredentialsFormField.fkCredentials] as LoginFormCredentials;
      try {
        await widget.onSubmit(
          context,
          credentials.username!,
          credentials.password!,
          form[ServerAddressFormField.fkServerAddress],
          _selectedClientCertificate, // Use cert from reachability check if available
        );
      } on PaperlessApiException catch (error) {
        if (mounted) showErrorMessage(context, error);
      } on ServerMessageException catch (error) {
        if (mounted) showLocalizedError(context, error.message);
      } on InfoMessageException catch (error) {
        if (mounted) showInfoMessage(context, error);
      } catch (error) {
        if (mounted) showGenericError(context, error);
      } finally {
        setState(() {
          _isFormSubmitted = false;
        });
      }
    }
  }
}
