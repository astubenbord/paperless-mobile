import 'package:flutter/material.dart';
import 'package:paperless_mobile/constants.dart';
import 'package:paperless_mobile/core/extensions/context_extensions.dart';
import 'package:paperless_mobile/core/widgets/unsupported_version_dialog.dart';
import 'package:paperless_mobile/routing/routes.dart';

Future<bool> guardUnsupportedApiVersion(
  BuildContext context,
  int apiVersion,
) async {
  if (apiVersion < latestSupportedApiVersion) {
    final goBackToLogin =
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          useRootNavigator: false,
          builder: (context) =>
              UnsupportedVersionDialog(apiVersion: apiVersion),
        ) ??
        false;
    if (goBackToLogin && context.mounted) {
      context.popUntil((route) => route.name == R.loginConnectToServer);
      return true;
    }
  }
  return false;
}
