import 'package:flutter/material.dart';
import 'package:paperless_mobile/core/model/file_download_type.dart';
import 'package:paperless_mobile/core/widgets/global_settings_builder.dart';
import 'package:paperless_mobile/features/settings/view/widgets/radio_settings_dialog.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class DefaultDownloadFileTypeSetting extends StatelessWidget {
  const DefaultDownloadFileTypeSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return GlobalSettingsBuilder(
      builder: (context, settings) {
        return ListTile(
          title: Text(S.of(context)!.defaultDownloadFileType),
          subtitle: Text(
            _downloadFileTypeToString(context, settings.defaultDownloadType),
          ),
          onTap: () async {
            final selectedValue = await showDialog<FileDownloadType>(
              context: context,
              builder: (context) {
                return RadioSettingsDialog<FileDownloadType>(
                  titleText: S.of(context)!.defaultDownloadFileType,
                  options: [
                    RadioOption(
                      value: FileDownloadType.alwaysAsk,
                      label: _downloadFileTypeToString(
                          context, FileDownloadType.alwaysAsk),
                    ),
                    RadioOption(
                      value: FileDownloadType.original,
                      label: _downloadFileTypeToString(
                          context, FileDownloadType.original),
                    ),
                    RadioOption(
                      value: FileDownloadType.archived,
                      label: _downloadFileTypeToString(
                          context, FileDownloadType.archived),
                    ),
                  ],
                  initialValue: settings.defaultDownloadType,
                );
              },
            );
            if (selectedValue != null) {
              settings
                ..defaultDownloadType = selectedValue
                ..save();
            }
          },
        );
      },
    );
  }

  String _downloadFileTypeToString(
      BuildContext context, FileDownloadType type) {
    switch (type) {
      case FileDownloadType.original:
        return S.of(context)!.original;
      case FileDownloadType.archived:
        return S.of(context)!.archivedPdf;
      case FileDownloadType.alwaysAsk:
        return S.of(context)!.alwaysAsk;
    }
  }
}
