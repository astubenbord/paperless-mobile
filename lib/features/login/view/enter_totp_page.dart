import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/keys.dart';

class EnterTotpPage extends StatefulWidget {
  final void Function(String code) onSubmit;
  final VoidCallback? onCancel;
  final ValueListenable<String?> errorTextListenable;

  const EnterTotpPage({
    super.key,
    required this.onSubmit,
    this.onCancel,
    required this.errorTextListenable,
  });

  @override
  State<EnterTotpPage> createState() => _EnterTotpPageState();
}

class _EnterTotpPageState extends State<EnterTotpPage> {
  final TextEditingController _controller = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Two-factor authentication',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ).padded(8),
            ValueListenableBuilder<String?>(
              valueListenable: widget.errorTextListenable,
              builder: (context, errorText, _) {
                return TextField(
                  key: TestKeys.login.totpCodeFormField,
                  controller: _controller,
                  autofocus: true,
                  maxLength: 6,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Enter the 6-digit code',
                    errorText: errorText,
                  ),
                  onSubmitted: (_) => _onSubmit(),
                );
              },
            ).paddedSymmetrically(horizontal: 8),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  key: TestKeys.login.totpCancelButton,
                  onPressed: _submitting
                      ? null
                      : () {
                          if (widget.onCancel != null) widget.onCancel!();
                        },
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  key: TestKeys.login.totpVerifyButton,
                  onPressed: _submitting ? null : _onSubmit,
                  child: _submitting
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Verify'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _onSubmit() async {
    final code = _controller.text.trim();
    if (code.length != 6) {
      setState(() {});
      return;
    }
    setState(() => _submitting = true);
    try {
      widget.onSubmit(code);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
