import 'package:flutter/material.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

enum DialogConfirmButtonStyle { normal, danger }

class DialogConfirmButton<T> extends StatelessWidget {
  final DialogConfirmButtonStyle style;
  final String? label;

  /// The value [Navigator.pop] will be called with. If [onPressed] is
  /// specified, this value will be ignored.
  final T? returnValue;

  /// Function called when the button is pressed. Takes precedence over [returnValue].
  final void Function()? onPressed;
  const DialogConfirmButton({
    super.key,
    this.style = DialogConfirmButtonStyle.normal,
    this.label,
    this.returnValue,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final normalStyle = ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(
        Theme.of(context).colorScheme.primaryContainer,
      ),
      foregroundColor: WidgetStatePropertyAll(
        Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
    final dangerStyle = ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(
        Theme.of(context).colorScheme.errorContainer,
      ),
      foregroundColor: WidgetStatePropertyAll(
        Theme.of(context).colorScheme.onErrorContainer,
      ),
    );

    late final ButtonStyle buttonStyle;
    switch (style) {
      case DialogConfirmButtonStyle.normal:
        buttonStyle = normalStyle;
        break;
      case DialogConfirmButtonStyle.danger:
        buttonStyle = dangerStyle;
        break;
    }

    final effectiveOnPressed =
        onPressed ?? () => Navigator.of(context).pop(returnValue ?? true);
    return ElevatedButton(
      style: buttonStyle,
      onPressed: effectiveOnPressed,
      child: Text(label ?? S.of(context)!.confirm),
    );
  }
}
