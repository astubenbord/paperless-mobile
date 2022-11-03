import 'package:flutter/material.dart';
import 'package:paperless_mobile/features/documents/model/document.model.dart';
import 'package:paperless_mobile/generated/l10n.dart';

class DeleteDocumentConfirmationDialog extends StatelessWidget {
  final DocumentModel document;
  const DeleteDocumentConfirmationDialog({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.of(context).documentsPageSelectionBulkDeleteDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            S.of(context).documentsPageSelectionBulkDeleteDialogWarningTextOne,
          ),
          const SizedBox(height: 16),
          Text(
            document.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
              S.of(context).documentsPageSelectionBulkDeleteDialogContinueText),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(S.of(context).genericActionCancelLabel),
        ),
        TextButton(
          style: ButtonStyle(
            foregroundColor:
                MaterialStateProperty.all(Theme.of(context).colorScheme.error),
          ),
          onPressed: () {
            Navigator.pop(context, true);
          },
          child: Text(S.of(context).genericActionDeleteLabel),
        ),
      ],
    );
  }
}
