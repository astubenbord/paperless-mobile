import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:paperless_mobile/core/model/error_message.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/login/bloc/authentication_cubit.dart';
import 'package:paperless_mobile/features/login/view/widgets/client_certificate_form_field.dart';
import 'package:paperless_mobile/features/login/view/widgets/server_address_form_field.dart';
import 'package:paperless_mobile/features/login/view/widgets/user_credentials_form_field.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:paperless_mobile/util.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormBuilderState>();

  bool _isLoginLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(S.of(context).loginPageTitle),
        bottom: _isLoginLoading
            ? const PreferredSize(
                preferredSize: Size(double.infinity, 4),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FormBuilder(
          key: _formKey,
          child: ListView(
            children: [
              const ServerAddressFormField().padded(),
              const UserCredentialsFormField(),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    S.of(context).loginPageAdvancedLabel,
                    style: Theme.of(context).textTheme.bodyText1,
                  ).padded(),
                ),
              ),
              const ClientCertificateFormField(),
              LayoutBuilder(builder: (context, constraints) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: constraints.maxWidth,
                    child: _buildLoginButton(),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      style: ButtonStyle(
        backgroundColor: MaterialStatePropertyAll(
          Theme.of(context).colorScheme.primaryContainer,
        ),
        elevation: const MaterialStatePropertyAll(0),
      ),
      onPressed: _login,
      child: Text(
        S.of(context).loginPageLoginButtonLabel,
      ),
    );
  }

  void _login() async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() => _isLoginLoading = true);
      final form = _formKey.currentState!.value;
      try {
        await BlocProvider.of<AuthenticationCubit>(context).login(
          credentials: form[UserCredentialsFormField.fkCredentials],
          serverUrl: form[ServerAddressFormField.fkServerAddress],
          clientCertificate:
              form[ClientCertificateFormField.fkClientCertificate],
        );
      } on ErrorMessage catch (error) {
        showError(context, error);
      } catch (unknownError) {
        showSnackBar(context, unknownError.toString());
      } finally {
        setState(() => _isLoginLoading = false);
      }
    }
  }
}
