import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:paperless_mobile/core/database/hive/hive_extensions.dart';
import 'package:paperless_mobile/features/login/cubit/authentication_cubit.dart';
import 'package:paperless_mobile/core/model/client_certificate.dart';
import 'package:paperless_mobile/features/login/view/login_page.dart';
import 'package:paperless_mobile/features/login/view/login_to_existing_account_page.dart';
import 'package:paperless_mobile/features/login/view/verify_identity_page.dart';
import 'package:paperless_mobile/features/login/view/widgets/login_transition_page.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/features/login/view/test_keys.dart';
import 'package:paperless_mobile/routing/navigation_keys.dart';
import 'package:paperless_mobile/routing/routes.dart';
part 'login_route.g.dart';

@TypedGoRoute<LoginRoute>(
  path: "/login",
  name: R.login,
  routes: [
    TypedGoRoute<SwitchingAccountsRoute>(
      path: "switching-account",
      name: R.switchingAccount,
    ),
    TypedGoRoute<AuthenticatingRoute>(
      path: 'authenticating',
      name: R.authenticating,
    ),
    TypedGoRoute<VerifyIdentityRoute>(
      path: 'verify-identity',
      name: R.verifyIdentity,
    ),
    TypedGoRoute<LoginToExistingAccountRoute>(
      path: 'existing',
      name: R.loginToExistingAccount,
    ),
    TypedGoRoute<RestoringSessionRoute>(
      path: 'restoring-session',
      name: R.restoringSession,
    ),
  ],
)
class LoginRoute extends GoRouteData with $LoginRoute {
  static final $parentNavigatorKey = rootNavigatorKey;
  final String? serverUrl;
  final String? username;
  final String? password;
  final ClientCertificate? $extra;

  const LoginRoute({
    this.serverUrl,
    this.username,
    this.password,
    this.$extra,
  });

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return LoginPage(
      initialServerUrl: serverUrl,
      initialUsername: username,
      initialPassword: password,
      initialClientCertificate: $extra,
    );
  }

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
    if (context.read<AuthenticationCubit>().state.isAuthenticated) {
      return "/landing";
    }
    return null;
  }
}

class SwitchingAccountsRoute extends GoRouteData with $SwitchingAccountsRoute {
  static final $parentNavigatorKey = rootNavigatorKey;

  const SwitchingAccountsRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return NoTransitionPage(
      child: LoginTransitionPage(
        text: S.of(context)!.switchingAccountsPleaseWait,
      ),
    );
  }
}

class AuthenticatingRoute extends GoRouteData with $AuthenticatingRoute {
  static final $parentNavigatorKey = rootNavigatorKey;

  final String checkLoginStageName;
  const AuthenticatingRoute(this.checkLoginStageName);

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    final stage = AuthenticatingStage.values.byName(checkLoginStageName);
    final text = switch (stage) {
      AuthenticatingStage.authenticating => S.of(context)!.authenticatingDots,
      AuthenticatingStage.persistingLocalUserData =>
        S.of(context)!.persistingUserInformation,
      AuthenticatingStage.fetchingUserInformation =>
        S.of(context)!.fetchingUserInformation,
    };
    return NoTransitionPage(
      child: LoginTransitionPage(
        key: TestKeys.login.loggingInScreen,
        text: text,
      ),
    );
  }
}

class VerifyIdentityRoute extends GoRouteData with $VerifyIdentityRoute {
  static final $parentNavigatorKey = rootNavigatorKey;

  final String userId;
  const VerifyIdentityRoute({required this.userId});

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return NoTransitionPage(
      child: VerifyIdentityPage(userId: userId),
    );
  }
}

class LoginToExistingAccountRoute extends GoRouteData
    with $LoginToExistingAccountRoute {
  static final $parentNavigatorKey = rootNavigatorKey;

  const LoginToExistingAccountRoute();

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
    if (Hive.localUserAccountBox.isEmpty) {
      return "/login";
    }
    return null;
  }

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return const NoTransitionPage(
      child: LoginToExistingAccountPage(),
    );
  }
}

class RestoringSessionRoute extends GoRouteData with $RestoringSessionRoute {
  static final $parentNavigatorKey = rootNavigatorKey;

  const RestoringSessionRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return NoTransitionPage(
      child: LoginTransitionPage(
        text: S.of(context)!.restoringSession,
      ),
    );
  }
}
