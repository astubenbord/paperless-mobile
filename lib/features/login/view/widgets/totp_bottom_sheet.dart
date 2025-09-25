import 'package:flutter/material.dart';
import 'package:paperless_mobile/features/login/view/enter_totp_page.dart';
import 'package:paperless_mobile/features/logging/data/logger.dart';

/// Shows a bottom sheet to enter a TOTP code.
/// onVerify receives the code and should return a String error message to display,
/// or null on success. Returns true if verification ultimately succeeded; false on cancel.
Future<bool> showTotpBottomSheet(
  BuildContext context, {
  required Future<String?> Function(String code) onVerify,
}) async {
  final errorText = ValueNotifier<String?>(null);

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: EnterTotpPage(
          errorTextListenable: errorText,
          onCancel: () {
            Navigator.of(ctx).pop(false);
          },
          onSubmit: (code) async {
            final err = await onVerify(code);
            if (err == null) {
              Navigator.of(ctx).pop(true);
            } else {
              logger.fw(
                "showTotpBottomSheet: TOTP verification failed with error: $err",
                className: 'showTotpBottomSheet',
                methodName: 'onSubmit',
              );
              errorText.value = err;
            }
          },
        ),
      );
    },
  );

  // result will be true on success, false on cancel, null on dismiss
  return result == true;
}
