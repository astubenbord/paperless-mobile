import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:paperless_mobile/core/service/connectivity_status.service.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';

class ServerAddressFormField extends StatefulWidget {
  static const String fkServerAddress = "serverAddress";
  const ServerAddressFormField({
    Key? key,
  }) : super(key: key);

  @override
  State<ServerAddressFormField> createState() => _ServerAddressFormFieldState();
}

class _ServerAddressFormFieldState extends State<ServerAddressFormField> {
  static const _ipv4Regex = r"((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4}";
  static const _ipv6Regex =
      r"(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))";
  static final _urlRegex = RegExp(
      r"^(https?:\/\/)(([\da-z\.-]+)\.([a-z\.]{2,6})|(((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4})|((([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))))(:\d{1,5})?([\/\w \.-]*)*\/?$");
  final TextEditingController _textEditingController = TextEditingController();
  ReachabilityStatus _reachabilityStatus = ReachabilityStatus.undefined;

  @override
  Widget build(BuildContext context) {
    return FormBuilderTextField(
      key: const ValueKey('login-server-address'),
      controller: _textEditingController,
      name: ServerAddressFormField.fkServerAddress,
      validator: FormBuilderValidators.compose(
        [
          FormBuilderValidators.required(
            errorText:
                S.of(context).loginPageServerUrlValidatorMessageRequiredText,
          ),
          FormBuilderValidators.match(
            _urlRegex.pattern,
            errorText: S
                .of(context)
                .loginPageServerUrlValidatorMessageInvalidAddressText,
          ),
        ],
      ),
      decoration: InputDecoration(
        suffixIcon: _buildIsReachableIcon(),
        hintText: "http://192.168.1.50:8000",
        labelText: S.of(context).loginPageServerUrlFieldLabel,
      ),
      onChanged: _updateIsAddressReachableStatus,
      onSubmitted: (value) {
        if (value == null) return;
        // Remove trailing slash if it is a valid address.
        final address = value.trim();
        _textEditingController.text = address;
        if (_urlRegex.hasMatch(address) && address.endsWith("/")) {
          _textEditingController.text = address.replaceAll(RegExp(r'\/$'), '');
        }
      },
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
    if (address == null || !_urlRegex.hasMatch(address)) {
      setState(() {
        _reachabilityStatus = ReachabilityStatus.undefined;
      });
      return;
    }
    //https://stackoverflow.com/questions/49648022/check-whether-there-is-an-internet-connection-available-on-flutter-app
    setState(() => _reachabilityStatus = ReachabilityStatus.testing);
    final isReachable = await context
        .read<ConnectivityStatusService>()
        .isServerReachable(address.trim());
    setState(
      () => _reachabilityStatus = isReachable
          ? ReachabilityStatus.reachable
          : ReachabilityStatus.notReachable,
    );
  }
}

enum ReachabilityStatus { reachable, notReachable, testing, undefined }
