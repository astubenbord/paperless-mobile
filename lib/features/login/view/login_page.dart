import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/type/types.dart';
import 'package:paperless_mobile/features/login/bloc/authentication_cubit.dart';
import 'package:paperless_mobile/features/login/view/widgets/form_fields/client_certificate_form_field.dart';
import 'package:paperless_mobile/features/login/view/widgets/form_fields/server_address_form_field.dart';
import 'package:paperless_mobile/features/login/view/widgets/form_fields/user_credentials_form_field.dart';
import 'package:paperless_mobile/features/login/view/widgets/login_pages/server_connection_page.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:paperless_mobile/util.dart';

import 'widgets/never_scrollable_scroll_behavior.dart';
import 'widgets/login_pages/server_login_page.dart';

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
                  curve: Curves.easeInOut,
                );
              },
            ),
            ServerLoginPage(
              formBuilderKey: _formKey,
              onDone: _login,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _login() async {
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
      } on PaperlessValidationErrors catch (error, stackTrace) {
        if (error.hasFieldUnspecificError) {
          showLocalizedError(context, error.fieldUnspecificError!);
        } else {
          showGenericError(context, error.values.first, stackTrace);
        }
      } catch (unknownError, stackTrace) {
        showGenericError(context, unknownError.toString(), stackTrace);
      }
    }
  }
}
