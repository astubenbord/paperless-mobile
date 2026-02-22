import 'package:flutter/material.dart';
import 'package:paperless_mobile/core/widgets/global_settings_builder.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class SkipDocumentPreprationOnShareSetting extends StatelessWidget {
  const SkipDocumentPreprationOnShareSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return GlobalSettingsBuilder(
      builder: (context, settings) {
        return SwitchListTile(
          title: Text(S.of(context)!.skipEditingReceivedFiles),
          subtitle: Text(S.of(context)!.uploadWithoutPromptingUploadForm),
          value: settings.skipDocumentPreprarationOnUpload,
          onChanged: (value) async {
            settings.skipDocumentPreprarationOnUpload = value;
            await settings.save();
          },
        );
      },
    );
  }
}
