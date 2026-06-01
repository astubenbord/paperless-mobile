import 'dart:io';

import 'package:flutter/material.dart';
import 'package:paperless_mobile/core/widgets/dialog_utils/dialog_cancel_button.dart';
import 'package:paperless_mobile/core/widgets/dialog_utils/dialog_confirm_button.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class PendingFilesInfoDialog extends StatelessWidget {
  final List<File> pendingFiles;
  const PendingFilesInfoDialog({super.key, required this.pendingFiles});

  @override
  Widget build(BuildContext context) {
    final fileCount = pendingFiles.length;
    return AlertDialog(
      title: Text("Pending Files"),
      content: Text(
        "$fileCount files are waiting to be uploaded. Do you want to upload them now?",
      ),
      actions: [
        DialogCancelButton(),
        DialogConfirmButton(label: S.of(context)!.upload),
      ],
    );
  }
}
