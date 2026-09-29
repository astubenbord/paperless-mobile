import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:paperless_mobile/features/search_index/view/search_indexing_page.dart';
import 'package:paperless_mobile/features/settings/view/settings_page.dart';
import 'package:paperless_mobile/routing/navigation_keys.dart';
import 'package:paperless_mobile/theme.dart';

import 'shells/authenticated_route.dart';

class SettingsRoute extends GoRouteData with $SettingsRoute {
  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      outerShellNavigatorKey;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: buildOverlayStyle(
        Theme.of(context),
        systemNavigationBarColor: Theme.of(context).colorScheme.surface,
      ),
      child: const SettingsPage(),
    );
  }
}

class SearchIndexingRoute extends GoRouteData with $SearchIndexingRoute {
  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      outerShellNavigatorKey;

  const SearchIndexingRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SearchIndexingPage();
  }
}
