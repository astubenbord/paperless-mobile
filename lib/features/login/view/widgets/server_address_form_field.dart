import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:paperless_mobile/core/service/connectivity_status_service.dart';
import 'package:paperless_mobile/features/login/model/client_certificate.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:provider/provider.dart';

class ServerAddressFormField extends StatefulWidget {
  static const String fkServerAddress = "serverAddress";

  final void Function(String address) onDone;
  const ServerAddressFormField({
    Key? key,
    required this.onDone,
  }) : super(key: key);

  @override
  State<ServerAddressFormField> createState() => _ServerAddressFormFieldState();
}

class _ServerAddressFormFieldState extends State<ServerAddressFormField> {
  final TextEditingController _textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return FormBuilderTextField(
      key: const ValueKey('login-server-address'),
      controller: _textEditingController,
      name: ServerAddressFormField.fkServerAddress,
      validator: FormBuilderValidators.required(
        errorText: S.of(context).loginPageServerUrlValidatorMessageRequiredText,
      ),
      decoration: InputDecoration(
        hintText: "http://192.168.1.50:8000",
        labelText: S.of(context).loginPageServerUrlFieldLabel,
      ),
      onSubmitted: (value) {
        if (value == null) return;
        // Remove trailing slash if it is a valid address.
        String address = value.trim();
        address = _replaceTrailingSlashes(address);
        _textEditingController.text = address;
        widget.onDone(address);
      },
    );
  }

  String _replaceTrailingSlashes(String src) {
    return src.replaceAll(RegExp(r'^\/+|\/+$'), '');
  }
}
