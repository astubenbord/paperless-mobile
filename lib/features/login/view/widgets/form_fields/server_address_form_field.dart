import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:paperless_mobile/generated/l10n.dart';

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
  bool _canClear = false;

  @override
  void initState() {
    super.initState();
    _textEditingController.addListener(() {
      if (_textEditingController.text.isNotEmpty) {
        setState(() {
          _canClear = true;
        });
      }
    });
  }

  final TextEditingController _textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return FormBuilderTextField(
      key: const ValueKey('login-server-address'),
      controller: _textEditingController,
      name: ServerAddressFormField.fkServerAddress,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(
          errorText:
              S.of(context).loginPageServerUrlValidatorMessageRequiredText,
        ),
        FormBuilderValidators.match(
          r"https?://.*",
          errorText:
              S.of(context).loginPageServerUrlValidatorMessageMissingSchemeText,
        )
      ]),
      decoration: InputDecoration(
        hintText: "http://192.168.1.50:8000",
        labelText: S.of(context).loginPageServerUrlFieldLabel,
        suffixIcon: _canClear
            ? IconButton(
                icon: Icon(Icons.clear),
                color: Theme.of(context).iconTheme.color,
                onPressed: () {
                  _textEditingController.clear();
                },
              )
            : null,
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
