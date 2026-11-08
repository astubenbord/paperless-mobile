import 'package:flutter/material.dart';
import 'package:paperless_mobile/core/widgets/dialog_utils/dialog_cancel_button.dart';
import 'package:paperless_mobile/core/widgets/dialog_utils/dialog_confirm_button.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class ConfirmBulkModifyLabelDialog extends StatelessWidget {
  final String content;
  const ConfirmBulkModifyLabelDialog({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(S.of(context)!.confirmAction),
      content: RichText(
        text: TextSpan(
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          text: content,
          children: [
            const TextSpan(text: "\n\n"),
            TextSpan(text: S.of(context)!.areYouSureYouWantToContinue),
          ],
        ),
      ),
      actions: const [
        DialogCancelButton(),
        DialogConfirmButton(style: DialogConfirmButtonStyle.danger),
      ],
    );
  }
}
