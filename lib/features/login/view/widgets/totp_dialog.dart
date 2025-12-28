import 'package:flutter/material.dart';
import 'package:paperless_mobile/core/widgets/dialog_utils/dialog_cancel_button.dart';
import 'package:paperless_mobile/core/widgets/dialog_utils/dialog_confirm_button.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class TotpDialog extends StatefulWidget {
  final Function(String code) onSubmit;

  const TotpDialog({
    super.key,
    required this.onSubmit,
  });

  @override
  State<TotpDialog> createState() => _TotpDialogState();
}

class _TotpDialogState extends State<TotpDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _autoValidate = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(S.of(context)!.twoFactorAuthentication),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.of(context)!.twoFactorAuthenticationRequired,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              autocorrect: false,
              autovalidateMode: _autoValidate
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return S.of(context)!.thisFieldIsRequired;
                }
                if (value.length != 6 || !RegExp(r'^\d+$').hasMatch(value)) {
                  return S.of(context)!.authenticatorCodeMustBeSixDigits;
                }
                return null;
              },
              decoration: InputDecoration(
                labelText: S.of(context)!.code,
                hintText: '123456',
                counterText: '',
              ),
              onFieldSubmitted: (value) => _handleSubmit(),
            ),
          ],
        ),
      ),
      actions: [
        const DialogCancelButton(),
        DialogConfirmButton(
          label: S.of(context)!.signIn,
          onPressed: _handleSubmit,
        ),
      ],
    );
  }

  void _handleSubmit() {
    setState(() {
      _autoValidate = true;
    });

    if (_formKey.currentState?.validate() ?? false) {
      widget.onSubmit(_controller.text);
    }
  }
}
