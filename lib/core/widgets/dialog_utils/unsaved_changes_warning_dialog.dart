import 'package:flutter/material.dart';
import 'package:paperless_mobile/core/widgets/dialog_utils/dialog_cancel_button.dart';
import 'package:paperless_mobile/core/widgets/dialog_utils/dialog_confirm_button.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class UnsavedChangesWarningDialog extends StatelessWidget {
  const UnsavedChangesWarningDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.of(context)!.discardChanges),
      content: Text(S.of(context)!.discardChangesWarning),
      actions: [
        const DialogCancelButton(),
        DialogConfirmButton(label: S.of(context)!.discard),
      ],
    );
  }
}
