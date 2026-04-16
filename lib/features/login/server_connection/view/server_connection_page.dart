import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/core/widgets/app_logs_footer_widget.dart';
import 'package:paperless_mobile/features/login/model/client_certificate.dart';
import 'package:paperless_mobile/features/login/model/reachability_status.dart';
import 'package:paperless_mobile/features/login/server_connection/cubit/server_connection_cubit.dart';
import 'package:paperless_mobile/features/login/server_connection/model/header_entry.dart';
import 'package:paperless_mobile/features/login/view/widgets/form_fields/additional_headers_form_field.dart';
import 'package:paperless_mobile/features/login/view/widgets/form_fields/client_certificate_form_field.dart';
import 'package:paperless_mobile/features/login/view/widgets/form_fields/server_address_form_field.dart';
import 'package:paperless_mobile/generated/assets.gen.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/routing/routes/auth_route.dart';

class ServerConnectionPage extends StatefulWidget {
  final String? initialHost;
  final ClientCertificate? initialClientCertificate;
  final List<HeaderEntry>? initialAdditionalHeaders;

  const ServerConnectionPage({
    super.key,
    this.initialClientCertificate,
    this.initialAdditionalHeaders,
    this.initialHost,
  });

  @override
  State<ServerConnectionPage> createState() => _ServerConnectionPageState();
}

class _ServerConnectionPageState extends State<ServerConnectionPage> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  void initState() {
    super.initState();
    if (widget.initialHost != null) {
      context.read<ServerConnectionCubit>().checkReachability(
        address: widget.initialHost!,
        clientCertificate: widget.initialClientCertificate,
        additionalHeaders: widget.initialAdditionalHeaders,
      );
    } else {
      context.read<ServerConnectionCubit>().reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      persistentFooterButtons: [AppLogsFooterWidget().padded()],
      persistentFooterAlignment: AlignmentDirectional.center,
      persistentFooterDecoration: BoxDecoration(),
      appBar: AppBar(title: Text(S.of(context)!.connectToPaperless)),
      body: SingleChildScrollView(
        child: FormBuilder(
          key: _formKey,
          child: Column(
            children: [
              Assets.logos.paperlessLogoGreenSvg
                  .svg(height: 150, width: 150)
                  .padded(),
              ServerAddressFormField(
                initialValue: widget.initialHost,
                onChanged: (_) {
                  context.read<ServerConnectionCubit>().reset();
                },
              ).paddedSymmetrically(horizontal: 12, vertical: 12),
              ClientCertificateFormField(
                initialBytes: widget.initialClientCertificate?.bytes,
                initialPassphrase: widget.initialClientCertificate?.passphrase,
              ).padded(),
              AdditionalHeadersFormField(
                name: 'additionalHeaders',
                initialHeaders: widget.initialAdditionalHeaders,
              ).padded(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  BlocConsumer<ServerConnectionCubit, ServerConnectionState>(
                    listener: (context, state) {
                      if (state is ServerConnectionSuccess) {
                        AuthenticateRoute(
                          serverUrl: state.serverUrl,
                          $extra: AuthRouteExtra(
                            clientCertificate: state.clientCertificate,
                            additionalHeaders: state.additionalHeaders,
                          ),
                        ).push(context);
                      }
                    },
                    builder: (context, state) {
                      return switch (state) {
                        ServerConnectionCheckingReachability() =>
                          FilledButton.icon(
                            onPressed: null,
                            label: Text(S.of(context)!.continueLabel),
                            icon: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSecondary,
                              ),
                            ),
                          ),
                        _ => FilledButton.icon(
                          onPressed: _onSubmit,
                          icon: Icon(Icons.arrow_forward),
                          label: Text(S.of(context)!.continueLabel),
                        ),
                      };
                    },
                  ),
                ],
              ).paddedSymmetrically(horizontal: 16, vertical: 8),
              _buildStatusIndicator().padded(),
            ],
          ),
        ),
      ),
    );
  }

  void _onSubmit() {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final clientCertificate =
          _formKey.currentState?.fields['clientCertificate']?.value
              as ClientCertificate?;
      final address =
          _formKey
                  .currentState
                  ?.fields[ServerAddressFormField.fkServerAddress]
                  ?.value
              as String;
      final additionalHeaders =
          _formKey.currentState?.fields['additionalHeaders']?.value
              as List<HeaderEntry>?;
      context.read<ServerConnectionCubit>().checkReachability(
        address: address,
        clientCertificate: clientCertificate,
        additionalHeaders: additionalHeaders,
      );
    }
  }

  Widget _buildStatusIndicator() {
    Color errorColor = Theme.of(context).colorScheme.error;
    Widget buildIconText(IconData icon, String text, [Color? color]) {
      return ListTile(
        title: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
        ),
        leading: Icon(icon, color: color),
      );
    }

    return BlocBuilder<ServerConnectionCubit, ServerConnectionState>(
      builder: (context, state) {
        if (state is! ServerConnectionUnreachable) {
          return const SizedBox.shrink();
        }
        final status = state.status;
        switch (status) {
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
      },
    );
  }
}
