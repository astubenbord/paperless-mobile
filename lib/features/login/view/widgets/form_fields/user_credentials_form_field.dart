import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:paperless_mobile/core/database/hive/hive_extensions.dart';

import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/login/model/login_form_credentials.dart';
import 'package:paperless_mobile/features/login/view/widgets/form_fields/api_key_form_field.dart';
import 'package:paperless_mobile/features/login/view/widgets/form_fields/obscured_input_text_form_field.dart';
import 'package:paperless_mobile/features/login/view/widgets/form_fields/server_address_form_field.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class UserCredentialsFormField extends StatefulWidget {
  static const fkCredentials = 'credentials';

  final VoidCallback? onFieldsSubmitted;
  final String? initialUsername;
  final String? initialPassword;
  final GlobalKey<FormBuilderState> formKey;
  final ValueChanged<bool>? onAuthModeChanged;
  final bool? useApiKey;
  final bool checkForExistingUser;

  const UserCredentialsFormField({
    super.key,
    this.onFieldsSubmitted,
    this.initialUsername,
    this.initialPassword,
    required this.formKey,
    this.onAuthModeChanged,
    this.useApiKey,
    this.checkForExistingUser = true,
  });

  @override
  State<UserCredentialsFormField> createState() =>
      _UserCredentialsFormFieldState();
}

class _UserCredentialsFormFieldState extends State<UserCredentialsFormField>
    with AutomaticKeepAliveClientMixin {
  final _usernameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _apiKeyFocusNode = FocusNode();

  bool get _useApiKey => widget.useApiKey ?? false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FormBuilderField<LoginFormCredentials?>(
      initialValue: LoginFormCredentials(
        password: widget.initialPassword,
        username: widget.initialUsername,
      ),
      name: UserCredentialsFormField.fkCredentials,
      builder: (field) => Column(
        children: [
          if (!_useApiKey) ...[
            TextFormField(
              key: const ValueKey('login-username'),
              focusNode: _usernameFocusNode,
              textCapitalization: TextCapitalization.none,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (value) {
                _passwordFocusNode.requestFocus();
              },
              autovalidateMode: AutovalidateMode.onUserInteraction,
              autocorrect: false,
              onChanged: (username) => field.didChange(
                field.value?.copyWith(username: username, apiKey: null) ??
                    LoginFormCredentials(username: username),
              ),
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return S.of(context)!.usernameMustNotBeEmpty;
                }
                if (widget.checkForExistingUser) {
                  final serverAddress = widget.formKey.currentState!
                      .getRawValue<String>(ServerAddressFormField.fkServerAddress);
                  if (serverAddress != null) {
                    final userExists = Hive.localUserAccountBox.values
                        .map((e) => e.id)
                        .contains('$value@$serverAddress');
                    if (userExists) {
                      return S.of(context)!.userAlreadyExists;
                    }
                  }
                }
                return null;
              },
              autofillHints: const [AutofillHints.username],
              decoration: InputDecoration(
                label: Text(S.of(context)!.username),
              ),
            ).padded(),
            ObscuredInputTextFormField(
              key: const ValueKey('login-password'),
              focusNode: _passwordFocusNode,
              label: S.of(context)!.password,
              onChanged: (password) => field.didChange(
                field.value?.copyWith(password: password, apiKey: null) ??
                    LoginFormCredentials(password: password),
              ),
              onFieldSubmitted: (_) {
                widget.onFieldsSubmitted?.call();
              },
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return S.of(context)!.passwordMustNotBeEmpty;
                }
                return null;
              },
            ).padded(),
          ] else ...[
            ApiKeyFormField(
              key: const ValueKey('login-apikey'),
              focusNode: _apiKeyFocusNode,
              label: S.of(context)!.apiKey,
              onChanged: (apiKey) => field.didChange(
                field.value?.copyWith(apiKey: apiKey, username: null, password: null) ??
                    LoginFormCredentials(apiKey: apiKey),
              ),
              onFieldSubmitted: (_) {
                widget.onFieldsSubmitted?.call();
              },
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return S.of(context)!.apiKeyRequired;
                }
                return null;
              },
            ).padded(),
          ],
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

/**
 * AutofillGroup(
      child: Column(
        children: [
          FormBuilderTextField(
            name: fkUsername,
            focusNode: _focusNodes[fkUsername],
            onSubmitted: (_) {
              FocusScope.of(context).requestFocus(_focusNodes[fkPassword]);
            },
            validator: FormBuilderValidators.required(
              errorText: S.of(context)!.usernameMustNotBeEmpty,
            ),
            autofillHints: const [AutofillHints.username],
            decoration: InputDecoration(
              labelText: S.of(context)!.username,
            ),
          ).padded(),
          FormBuilderTextField(
            name: fkPassword,
            focusNode: _focusNodes[fkPassword],
            onSubmitted: (_) {
              FocusScope.of(context).unfocus();
            },
            autofillHints: const [AutofillHints.password],
            validator: FormBuilderValidators.required(
              errorText: S.of(context)!.passwordMustNotBeEmpty,
            ),
            obscureText: true,
            decoration: InputDecoration(
              labelText: S.of(context)!.password,
            ),
          ).padded(),
        ],
      ),
    );
 */
