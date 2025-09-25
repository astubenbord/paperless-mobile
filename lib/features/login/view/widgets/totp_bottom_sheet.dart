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
  logger.fd(
    "showTotpBottomSheet: Opening TOTP bottom sheet",
    className: 'showTotpBottomSheet',
    methodName: 'showTotpBottomSheet',
  );

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
            logger.fd(
              "showTotpBottomSheet: User canceled TOTP entry",
              className: 'showTotpBottomSheet',
              methodName: 'onCancel',
            );
            Navigator.of(ctx).pop(false);
          },
          onSubmit: (code) async {
            logger.fd(
              "showTotpBottomSheet: User submitted TOTP code (length: ${code.length})",
              className: 'showTotpBottomSheet',
              methodName: 'onSubmit',
            );
            final err = await onVerify(code);
            if (err == null) {
              logger.fd(
                "showTotpBottomSheet: TOTP verification successful, closing sheet",
                className: 'showTotpBottomSheet',
                methodName: 'onSubmit',
              );
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

  logger.fd(
    "showTotpBottomSheet: Bottom sheet closed with result: $result",
    className: 'showTotpBottomSheet',
    methodName: 'showTotpBottomSheet',
  );

  // result will be true on success, false on cancel, null on dismiss
  return result == true;
}
