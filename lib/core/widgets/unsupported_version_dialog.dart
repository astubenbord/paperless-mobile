import 'package:flutter/material.dart';
import 'package:paperless_mobile/constants.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class UnsupportedVersionDialog extends StatelessWidget {
  final int apiVersion;
  const UnsupportedVersionDialog({super.key, required this.apiVersion});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.warning, size: 48, color: Colors.yellow),
      title: Text(S.of(context)!.unsupportedVersionTitle),
      content: Text(
        S
            .of(context)!
            .unsupportedVersionWarning(apiVersion, latestSupportedApiVersion),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(S.of(context)!.backToLogin),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(S.of(context)!.continueAnyway),
        ),
      ],
    );
  }
}
