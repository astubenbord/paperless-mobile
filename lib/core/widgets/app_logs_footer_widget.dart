import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:paperless_mobile/constants.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/routing/routes/app_logs_route.dart';

class AppLogsFooterWidget extends StatelessWidget {
  final bool showVersion;
  const AppLogsFooterWidget({super.key, this.showVersion = true});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: Theme.of(context).textTheme.labelLarge,
        children: [
          if (showVersion) ...[
            TextSpan(text: S.of(context)!.version(packageInfo.version)),
            WidgetSpan(child: SizedBox(width: 24)),
          ],
          TextSpan(
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
            text: S.of(context)!.appLogs(''),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                AppLogsRoute().push(context);
              },
          ),
        ],
      ),
    );
  }
}
