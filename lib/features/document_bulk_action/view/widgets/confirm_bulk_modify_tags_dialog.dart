import 'package:flutter/material.dart';
import 'package:paperless_mobile/core/widgets/dialog_utils/dialog_cancel_button.dart';
import 'package:paperless_mobile/core/widgets/dialog_utils/dialog_confirm_button.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class ConfirmBulkModifyTagsDialog extends StatelessWidget {
  final int selectionCount;
  final List<String> removeTags;
  final List<String> addTags;
  const ConfirmBulkModifyTagsDialog({
    super.key,
    required this.removeTags,
    required this.addTags,
    required this.selectionCount,
  });

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
          text: _buildText(context),
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

  String _buildText(BuildContext context) {
    if (removeTags.isNotEmpty && addTags.isNotEmpty) {
      return S
          .of(context)!
          .bulkEditTagsModifyMessage(
            addTags.join(", "),
            selectionCount,
            removeTags.join(", "),
          );
    } else if (removeTags.isNotEmpty) {
      return S
          .of(context)!
          .bulkEditTagsRemoveMessage(selectionCount, removeTags.join(", "));
    } else {
      return S
          .of(context)!
          .bulkEditTagsAddMessage(selectionCount, addTags.join(", "));
    }
  }
}
