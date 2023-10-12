import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/core/service/connectivity_status_service.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/helpers/message_helpers.dart';

typedef OfflineBuilder = Widget Function(BuildContext context, Widget? child);

class ConnectivityAwareActionWrapper extends StatelessWidget {
  final OfflineBuilder offlineBuilder;
  final Widget child;
  final bool disabled;
  final String? disabledReason;

  static Widget disabledBuilder(BuildContext context, Widget? child) {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        0.2126, 0.7152, 0.0722, 0, 0, //
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0, 0, 0, 1, 0,
      ]),
      child: child,
    );
  }

  ///
  /// Wrapper widget which is used to disable an actionable [child]
  /// (like buttons, chips etc.) which require a connection to the internet.
  ///
  ///
  const ConnectivityAwareActionWrapper({
    super.key,
    this.offlineBuilder = ConnectivityAwareActionWrapper.disabledBuilder,
    required this.child,
    this.disabled = false,
    this.disabledReason
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: context.read<ConnectivityStatusService>().connectivityChanges(),
      builder: (context, snapshot) {
        final isOffline =!snapshot.hasData || snapshot.data == false;
        final disableButton =
             isOffline || disabled;
        if (disableButton) {
          return GestureDetector(
            onTap: () {
              HapticFeedback.heavyImpact();
              var errorString = "";
              if (isOffline) {
                errorString = S.of(context)!.youAreCurrentlyOffline;
                if (disabled) {
                  errorString = errorString + '\n';
                }
              }
              if (disabled && disabledReason != null) {
                errorString = errorString + disabledReason!;
              }
              showSnackBar(context, errorString);
            },
            child: AbsorbPointer(
              child: offlineBuilder(context, child),
            ),
          );
        }
        return child;
      },
    );
  }
}
