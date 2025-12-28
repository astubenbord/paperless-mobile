import 'package:flutter/material.dart';
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
    return AlertDialog(
      title: Text(S.of(context)!.twoFactorAuthentication),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(S.of(context)!.twoFactorAuthenticationRequired),
          const SizedBox(height: 16),
          TextField(
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
            onSubmitted: widget.onSubmit,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(S.of(context)!.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              widget.onSubmit(_controller.text);
            }
          },
          child: Text(S.of(context)!.signIn),
        ),
      ],
    );
  }
}
