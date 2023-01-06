import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:paperless_mobile/core/service/connectivity_status_service.dart';
import 'package:paperless_mobile/core/widgets/paperless_logo.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/login/model/reachability_status.dart';
import 'package:paperless_mobile/features/login/view/widgets/form_fields/client_certificate_form_field.dart';
import 'package:paperless_mobile/features/login/view/widgets/form_fields/server_address_form_field.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:provider/provider.dart';

class ServerConnectionPage extends StatefulWidget {
  final GlobalKey<FormBuilderState> formBuilderKey;
  final void Function() onContinue;

  const ServerConnectionPage({
    super.key,
    required this.formBuilderKey,
    required this.onContinue,
  });

  @override
  State<ServerConnectionPage> createState() => _ServerConnectionPageState();
}

class _ServerConnectionPageState extends State<ServerConnectionPage> {
  ReachabilityStatus _reachabilityStatus = ReachabilityStatus.unknown;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).loginPageTitle),
      ),
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          ServerAddressFormField(
            onDone: (address) {
              _updateReachability();
            },
          ).padded(),
          ClientCertificateFormField(
            onChanged: (_) => _updateReachability(),
          ).padded(),
          _buildStatusIndicator(),
        ],
      ).padded(),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FilledButton(
              child: Text(S.of(context).loginPageContinueLabel),
              onPressed: _reachabilityStatus == ReachabilityStatus.reachable
                  ? widget.onContinue
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateReachability() async {
    final status = await context
        .read<ConnectivityStatusService>()
        .isPaperlessServerReachable(
          widget.formBuilderKey.currentState!
              .getRawValue(ServerAddressFormField.fkServerAddress),
          widget.formBuilderKey.currentState?.getRawValue(
            ClientCertificateFormField.fkClientCertificate,
          ),
        );
    setState(() => _reachabilityStatus = status);
  }

  Widget _buildStatusIndicator() {
    Color errorColor = Theme.of(context).colorScheme.error;
    switch (_reachabilityStatus) {
      case ReachabilityStatus.unknown:
        return Container();
      case ReachabilityStatus.reachable:
        return _buildIconText(
          Icons.done,
          S.of(context).loginPageReachabilitySuccessText,
          Colors.green,
        );
      case ReachabilityStatus.notReachable:
        return _buildIconText(
          Icons.close,
          S.of(context).loginPageReachabilityNotReachableText,
          errorColor,
        );
      case ReachabilityStatus.unknownHost:
        return _buildIconText(
          Icons.close,
          S.of(context).loginPageReachabilityUnresolvedHostText,
          errorColor,
        );
      case ReachabilityStatus.missingClientCertificate:
        return _buildIconText(
          Icons.close,
          S.of(context).loginPageReachabilityMissingClientCertificateText,
          errorColor,
        );
      case ReachabilityStatus.invalidClientCertificateConfiguration:
        return _buildIconText(
          Icons.close,
          S
              .of(context)
              .loginPageReachabilityInvalidClientCertificateConfigurationText,
          errorColor,
        );
    }
  }

  Widget _buildIconText(
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
}
