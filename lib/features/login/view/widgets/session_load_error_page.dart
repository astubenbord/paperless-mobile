import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/routing/routes/app_logs_route.dart';
import 'package:paperless_mobile/theme.dart';

/// Shown when the session data (user profile, UI settings, API version) could
/// not be loaded, e.g. because the server was unreachable on app start.
///
/// Offers a manual retry and retries automatically when the app returns to the
/// foreground (e.g. after switching networks), instead of leaving an empty
/// screen until the app is restarted.
class SessionLoadErrorPage extends StatefulWidget {
  final VoidCallback onRetry;

  const SessionLoadErrorPage({super.key, required this.onRetry});

  @override
  State<SessionLoadErrorPage> createState() => _SessionLoadErrorPageState();
}

class _SessionLoadErrorPageState extends State<SessionLoadErrorPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.onRetry();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: buildOverlayStyle(
          theme,
          systemNavigationBarColor: theme.colorScheme.surface,
        ),
        child: Scaffold(
          body: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_off_outlined,
                    size: 48,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    S.of(context)!.couldNotLoadUserProfile,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: Text(S.of(context)!.tryAgain),
                    onPressed: widget.onRetry,
                  ),
                ],
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: TextButton(
                  child: Text(S.of(context)!.appLogs('')),
                  onPressed: () {
                    AppLogsRoute().push(context);
                  },
                ),
              ),
            ],
          ).padded(16),
        ),
      ),
    );
  }
}
