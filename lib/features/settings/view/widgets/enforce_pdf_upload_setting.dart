import 'package:flutter/material.dart';
import 'package:paperless_mobile/core/widgets/global_settings_builder.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class EnforcePdfUploadSetting extends StatelessWidget {
  const EnforcePdfUploadSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return GlobalSettingsBuilder(builder: (context, settings) {
      return SwitchListTile(
        title: Text(S.of(context)!.uploadScansAsPdf),
        subtitle: Text(S.of(context)!.convertSinglePageScanToPdf),
        value: settings.enforceSinglePagePdfUpload,
        onChanged: (value) async {
          settings.enforceSinglePagePdfUpload = value;
          await settings.save();
        },
      );
    });
  }
}
