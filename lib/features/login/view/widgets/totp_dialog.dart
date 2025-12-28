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
      content: Column(
        mainAxisSize: MainAxisSize.min,
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
            decoration: InputDecoration(
              labelText: S.of(context)!.code,
              hintText: '123456',
              counterText: '',
            ),
            onFieldSubmitted: (value) => widget.onSubmit(value),
          ),
        ],
      ),
      actions: [
        const DialogCancelButton(),
        DialogConfirmButton(
          label: S.of(context)!.signIn,
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              widget.onSubmit(_controller.text);
            }
          },
        ),
      ],
    );
  }
}
