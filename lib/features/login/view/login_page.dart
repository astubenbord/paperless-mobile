import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/features/login/bloc/authentication_cubit.dart';
import 'package:paperless_mobile/features/login/view/widgets/client_certificate_form_field.dart';
import 'package:paperless_mobile/features/login/view/widgets/server_address_form_field.dart';
import 'package:paperless_mobile/features/login/view/widgets/server_connection_page.dart';
import 'package:paperless_mobile/features/login/view/widgets/user_credentials_form_field.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:paperless_mobile/util.dart';

import 'widgets/never_scrollable_scroll_behavior.dart';
import 'widgets/server_login_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormBuilderState>();

  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // appBar: AppBar(
      //   title: Text(S.of(context).loginPageTitle),
      //   bottom: _isLoginLoading
      //       ? const PreferredSize(
      //           preferredSize: Size(double.infinity, 4),
      //           child: LinearProgressIndicator(),
      //         )
      //       : null,
      // ),
      body: FormBuilder(
        key: _formKey,
        child: PageView(
          controller: _pageController,
          scrollBehavior: NeverScrollableScrollBehavior(),
          children: [
            ServerConnectionPage(
              formBuilderKey: _formKey,
              onContinue: () {
                _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut);
              },
            ),
            ServerLoginPage(
              formBuilderKey: _formKey,
              onDone: _login,
            ),
          ],
        ),
      ),
      // Padding(
      //   padding: const EdgeInsets.all(8.0),
      //   child: FormBuilder(
      //     key: _formKey,
      //     child: ListView(
      //       children: [
      //         const ServerAddressFormField().padded(),
      //         const UserCredentialsFormField(),
      //         Align(
      //           alignment: Alignment.centerLeft,
      //           child: Padding(
      //             padding: const EdgeInsets.only(top: 16.0),
      //             child: Text(
      //               S.of(context).loginPageAdvancedLabel,
      //               style: Theme.of(context).textTheme.bodyLarge,
      //             ).padded(),
      //           ),
      //         ),
      //         const ClientCertificateFormField(),
      //         LayoutBuilder(builder: (context, constraints) {
      //           return Padding(
      //             padding: const EdgeInsets.all(8.0),
      //             child: SizedBox(
      //               width: constraints.maxWidth,
      //               child: _buildLoginButton(),
      //             ),
      //           );
      //         }),
      //       ],
      //     ),
      //   ),
      // ),
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      key: const ValueKey('login-login-button'),
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
      final form = _formKey.currentState!.value;
      try {
        await context.read<AuthenticationCubit>().login(
              credentials: form[UserCredentialsFormField.fkCredentials],
              serverUrl: form[ServerAddressFormField.fkServerAddress],
              clientCertificate:
                  form[ClientCertificateFormField.fkClientCertificate],
            );
      } on PaperlessServerException catch (error, stackTrace) {
        showErrorMessage(context, error, stackTrace);
      } on Map<String, dynamic> catch (error, stackTrace) {
        showGenericError(context, error.values.first, stackTrace);
      } catch (unknownError, stackTrace) {
        showGenericError(context, unknownError.toString(), stackTrace);
      } finally {}
    }
  }
}
