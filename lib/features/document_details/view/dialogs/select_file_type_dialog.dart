import 'package:flutter/material.dart';
import 'package:paperless_mobile/core/widgets/dialog_utils/dialog_cancel_button.dart';
import 'package:paperless_mobile/features/settings/model/file_download_type.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class SelectFileTypeDialog extends StatefulWidget {
  final void Function(FileDownloadType downloadType) onRememberSelection;
  const SelectFileTypeDialog({super.key, required this.onRememberSelection});

  @override
  State<SelectFileTypeDialog> createState() => _SelectFileTypeDialogState();
}

class _SelectFileTypeDialogState extends State<SelectFileTypeDialog> {
  bool _rememberSelection = false;
  FileDownloadType _downloadType = FileDownloadType.original;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.of(context)!.chooseFiletype),
      content: RadioGroup<FileDownloadType>(
        groupValue: _downloadType,
        onChanged: (value) {
          if (value != null) {
            setState(() => _downloadType = value);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile(
              value: FileDownloadType.original,
              title: Text(S.of(context)!.original),
            ),
            RadioListTile(
              value: FileDownloadType.archived,
              title: Text(S.of(context)!.archivedPdf),
            ),
            const Divider(),
            CheckboxListTile(
              controlAffinity: ListTileControlAffinity.leading,
              value: _rememberSelection,
              onChanged: (value) =>
                  setState(() => _rememberSelection = value ?? false),
              title: Text(
                S.of(context)!.rememberDecision,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ],
        ),
      ),
      actions: [
        const DialogCancelButton(),
        ElevatedButton(
          child: Text(S.of(context)!.select),
          onPressed: () {
            if (_rememberSelection) {
              widget.onRememberSelection(_downloadType);
            }
            Navigator.of(
              context,
            ).pop(_downloadType == FileDownloadType.original);
          },
        ),
      ],
    );
  }
}
