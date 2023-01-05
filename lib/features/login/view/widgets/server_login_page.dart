import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/login/view/widgets/server_address_form_field.dart';
import 'package:paperless_mobile/features/login/view/widgets/user_credentials_form_field.dart';

class ServerLoginPage extends StatefulWidget {
  final VoidCallback onDone;
  final GlobalKey<FormBuilderState> formBuilderKey;
  const ServerLoginPage({
    super.key,
    required this.onDone,
    required this.formBuilderKey,
  });

  @override
  State<ServerLoginPage> createState() => _ServerLoginPageState();
}

class _ServerLoginPageState extends State<ServerLoginPage> {
  @override
  Widget build(BuildContext context) {
    final serverAddress = (widget.formBuilderKey.currentState
            ?.getRawValue(ServerAddressFormField.fkServerAddress) as String?)
        ?.replaceAll(RegExp(r'https?://'), '');
    return Scaffold(
      appBar: AppBar(
        title: Text("Sign In"),
      ),
      body: ListView(
        children: [
          Text("Sign in to $serverAddress").padded(),
          UserCredentialsFormField(),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FilledButton(
              onPressed: widget.onDone,
              child: Text("Sign In"),
            )
          ],
        ),
      ),
    );
  }
}
