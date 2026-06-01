import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:paperless_mobile/features/logging/cubit/app_logs_cubit.dart';
import 'package:paperless_mobile/features/logging/view/app_logs_page.dart';
import 'package:paperless_mobile/routing/navigation_keys.dart';
import 'package:paperless_mobile/theme.dart';

part 'app_logs_route.g.dart';

@TypedGoRoute<AppLogsRoute>(path: '/app-logs')
class AppLogsRoute extends GoRouteData with $AppLogsRoute {
  static final $parentNavigatorKey = rootNavigatorKey;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return AnnotatedRegion(
      value: buildOverlayStyle(Theme.of(context)),
      child: BlocProvider(
        create: (context) =>
            AppLogsCubit(DateTime.now(), context.read())
              ..loadLogs(DateTime.now()),
        child: AppLogsPage(key: state.pageKey),
      ),
    );
  }
}
