import 'package:flutter/material.dart';
import 'package:paperless_mobile/core/widgets/dialog_utils/dialog_cancel_button.dart';
import 'package:paperless_mobile/core/widgets/dialog_utils/dialog_confirm_button.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class SavedViewChangedDialog extends StatelessWidget {
  const SavedViewChangedDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.of(context)!.discardChanges),
      content: Text(S.of(context)!.savedViewChangedDialogContent),
      actionsOverflowButtonSpacing: 8,
      actions: [
        const DialogCancelButton(),
        DialogConfirmButton(
          label: S.of(context)!.resetFilter,
          style: DialogConfirmButtonStyle.danger,
          returnValue: true,
        ),
      ],
    );
  }
}
