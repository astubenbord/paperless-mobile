import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:paperless_mobile/core/service/connectivity_status.service.dart';
import 'package:paperless_mobile/di_initializer.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class ServerAddressFormField extends StatefulWidget {
  static const String fkServerAddress = "serverAddress";
  const ServerAddressFormField({
    Key? key,
  }) : super(key: key);

  @override
  State<ServerAddressFormField> createState() => _ServerAddressFormFieldState();
}

class _ServerAddressFormFieldState extends State<ServerAddressFormField> {
  ReachabilityStatus _reachabilityStatus = ReachabilityStatus.undefined;

  @override
  Widget build(BuildContext context) {
    return FormBuilderTextField(
      name: ServerAddressFormField.fkServerAddress,
      validator: FormBuilderValidators.required(
        errorText: S.of(context).loginPageServerUrlValidatorMessageText,
      ),
      decoration: InputDecoration(
        suffixIcon: _buildIsReachableIcon(),
        hintText: "http://192.168.1.50:8000",
        labelText: S.of(context).loginPageServerUrlFieldLabel,
      ),
      onChanged: _updateIsAddressReachableStatus,
    );
  }

  Widget? _buildIsReachableIcon() {
    switch (_reachabilityStatus) {
      case ReachabilityStatus.reachable:
        return const Icon(
          Icons.done,
          color: Colors.green,
        );
      case ReachabilityStatus.notReachable:
        return Icon(
          Icons.close,
          color: Theme.of(context).colorScheme.error,
        );
      case ReachabilityStatus.testing:
        return const RefreshProgressIndicator();
      case ReachabilityStatus.undefined:
        return null;
    }
  }

  void _updateIsAddressReachableStatus(String? address) async {
    if (address == null || address.isEmpty) {
      setState(() {
        _reachabilityStatus = ReachabilityStatus.undefined;
      });
      return;
    }
    //https://stackoverflow.com/questions/49648022/check-whether-there-is-an-internet-connection-available-on-flutter-app
    setState(() => _reachabilityStatus = ReachabilityStatus.testing);
    final isReachable =
        await getIt<ConnectivityStatusService>().isServerReachable(address);
    if (isReachable) {
      setState(() => _reachabilityStatus = ReachabilityStatus.reachable);
    } else {
      setState(() => _reachabilityStatus = ReachabilityStatus.notReachable);
    }
  }
}

enum ReachabilityStatus { reachable, notReachable, testing, undefined }
