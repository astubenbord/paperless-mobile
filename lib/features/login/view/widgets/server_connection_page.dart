import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:paperless_mobile/core/service/connectivity_status_service.dart';
import 'package:paperless_mobile/core/widgets/paperless_logo.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/login/model/reachability_status.dart';
import 'package:paperless_mobile/features/login/view/widgets/client_certificate_form_field.dart';
import 'package:paperless_mobile/features/login/view/widgets/server_address_form_field.dart';
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
    final logoHeight = MediaQuery.of(context).size.width / 2;
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
              child: Text("Continue"),
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
          "Connection established.",
          Colors.green,
        );
      case ReachabilityStatus.notReachable:
        return _buildIconText(
          Icons.close,
          "Could not establish a connection to the server.",
          errorColor,
        );
      case ReachabilityStatus.unknownHost:
        return _buildIconText(
          Icons.close,
          "Host could not be resolved.",
          errorColor,
        );
      case ReachabilityStatus.missingClientCertificate:
        return _buildIconText(
          Icons.close,
          "A client certificate was expected but not sent. Please provide a certificate.",
          errorColor,
        );
      case ReachabilityStatus.invalidClientCertificateConfiguration:
        return _buildIconText(
          Icons.close,
          "Incorrect or missing client certificate passphrase.",
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
