import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:paperless_mobile/core/widgets/dialog_utils/dialog_cancel_button.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class BulkDownloadTargetDirectoryDialog extends StatefulWidget {
  final String initialDirectoryPath;
  final int documentsCount;

  const BulkDownloadTargetDirectoryDialog({
    super.key,
    required this.initialDirectoryPath,
    required this.documentsCount,
  });

  @override
  State<BulkDownloadTargetDirectoryDialog> createState() =>
      _BulkDownloadTargetDirectoryDialogState();
}

class _BulkDownloadTargetDirectoryDialogState
    extends State<BulkDownloadTargetDirectoryDialog> {
  late String _directoryPath = widget.initialDirectoryPath;
  bool _isSelectingDirectory = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.of(context)!.downloadDocumentTooltip),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(S.of(context)!.countSelected(widget.documentsCount)),
          const SizedBox(height: 8),
          Text(
            S.of(context)!.storagePath,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          Text(
            _directoryPath,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _isSelectingDirectory ? null : _onSelectDirectory,
            icon: const Icon(Icons.folder_open),
            label: Text(S.of(context)!.select),
          ),
        ],
      ),
      actions: [
        const DialogCancelButton(),
        ElevatedButton(
          onPressed: _directoryPath.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop(_directoryPath.trim()),
          child: Text(S.of(context)!.save),
        ),
      ],
    );
  }

  Future<void> _onSelectDirectory() async {
    setState(() {
      _isSelectingDirectory = true;
    });
    try {
      final path = await FilePicker.platform.getDirectoryPath(
        initialDirectory: _directoryPath,
        dialogTitle: S.of(context)!.storagePath,
      );
      if (path == null || path.trim().isEmpty || !mounted) {
        return;
      }
      setState(() {
        _directoryPath = path;
      });
    } catch (_) {
      return;
    } finally {
      if (mounted) {
        setState(() {
          _isSelectingDirectory = false;
        });
      }
    }
  }
}
