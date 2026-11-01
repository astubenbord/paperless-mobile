import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:paperless_mobile/core/store/local_store.dart';
import 'package:paperless_mobile/core/tunnel/tunnel_manager.dart';
import 'package:paperless_mobile/features/login/authenticate_user/cubit/authenticate_user_cubit.dart';
import 'package:paperless_mobile/features/login/authenticate_user/model/authentication_credentials.dart';
import 'package:paperless_mobile/features/login/authenticate_user/view/authenticate_user_page.dart';
import 'package:paperless_mobile/features/login/authenticate_user/view/otp_input_page.dart';
import 'package:paperless_mobile/features/login/model/client_certificate.dart';
import 'package:paperless_mobile/features/login/server_connection/cubit/server_connection_cubit.dart';
import 'package:paperless_mobile/features/login/server_connection/model/header_entry.dart';
import 'package:paperless_mobile/features/login/server_connection/view/server_connection_page.dart';
import 'package:paperless_mobile/features/login/view/add_user_loading_page.dart';
import 'package:paperless_mobile/features/login/view/select_account_page.dart';
import 'package:paperless_mobile/features/login/view/verify_identity_page.dart';
import 'package:paperless_mobile/features/login/view/widgets/login_transition_page.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/routing/navigation_keys.dart';
import 'package:paperless_mobile/routing/routes.dart';

part 'auth_route.g.dart';

@TypedGoRoute<AuthRoute>(
  path: '/auth',
  name: R.loginConnectToServer,
  routes: [
    TypedGoRoute<AuthenticateRoute>(path: 'login', name: R.loginAuthenticate),
    TypedGoRoute<OtpRoute>(path: 'otp', name: R.loginOtp),
    TypedGoRoute<SwitchingAccountsRoute>(
      path: "switching-account",
      name: R.switchingAccount,
    ),
    TypedGoRoute<VerifyIdentityRoute>(
      path: 'verify-identity',
      name: R.verifyIdentity,
    ),
    TypedGoRoute<RestoringSessionRoute>(
      path: 'restoring-session',
      name: R.restoringSession,
    ),
    TypedGoRoute<LoginToExistingAccountRoute>(
      path: 'select-account',
      name: R.loginToExistingAccount,
    ),
    TypedGoRoute<AddUserRoute>(path: 'set-active-user', name: R.setActiveUser),
    // TypedGoRoute<AddAcc>(path: 'add-account', name: R.addAccount),
  ],
)
class AuthRoute extends GoRouteData with $AuthRoute {
  static final $parentNavigatorKey = rootNavigatorKey;

  final String? initialHost;

  const AuthRoute({this.initialHost});

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return MaterialPage(
      child: BlocProvider(
        create: (context) => ServerConnectionCubit(
          context.read(),
          context.read<TunnelManager>(),
        ),
        child: ServerConnectionPage(initialHost: initialHost),
      ),
    );
  }
}

class AuthRouteExtra {
  final AuthenticationCredentials? credentials;
  final ClientCertificate? clientCertificate;
  final List<HeaderEntry>? additionalHeaders;

  const AuthRouteExtra({
    this.clientCertificate,
    this.additionalHeaders,
    this.credentials,
  });
}

class AddUserRouteExtra {
  final String token;
  final ClientCertificate? clientCertificate;
  final List<HeaderEntry>? additionalHeaders;

  const AddUserRouteExtra({
    required this.token,
    this.clientCertificate,
    this.additionalHeaders,
  });
}

class AuthenticateRoute extends GoRouteData with $AuthenticateRoute {
  static final $parentNavigatorKey = rootNavigatorKey;

  final String serverUrl;
  final AuthRouteExtra? $extra;

  const AuthenticateRoute({required this.serverUrl, this.$extra});

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return CustomTransitionPage(
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: animation.drive(
            Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeInOut)),
          ),
          child: child,
        );
      },
      child: BlocProvider(
        create: (context) =>
            AuthenticateUserCubit(context.read<TunnelManager>()),
        child: AuthenticateUserPage(
          serverUrl: serverUrl,
          initialCredentials: $extra?.credentials,
          clientCertificate: $extra?.clientCertificate,
          additionalHeaders: $extra?.additionalHeaders,
        ),
      ),
    );
  }
}

class OtpRouteExtra {
  final AuthenticationCredentials credentials;
  final ClientCertificate? clientCertificate;

  const OtpRouteExtra({required this.credentials, this.clientCertificate});
}

class OtpRoute extends GoRouteData with $OtpRoute {
  static final $parentNavigatorKey = rootNavigatorKey;

  final String serverUrl;
  final OtpRouteExtra $extra;

  const OtpRoute({required this.serverUrl, required this.$extra});

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return BlocProvider(
      create: (context) => AuthenticateUserCubit(context.read<TunnelManager>()),
      child: OtpInputPage(
        serverUrl: serverUrl,
        clientCertificate: $extra.clientCertificate,
        credentials: $extra.credentials,
      ),
    );
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

class AddUserRoute extends GoRouteData with $AddUserRoute {
  final String serverUrl;
  final AddUserRouteExtra $extra;

  AddUserRoute({required this.serverUrl, required this.$extra});

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return AddUserLoadingPage(
      serverUrl: serverUrl,
      token: $extra.token,
      clientCertificate: $extra.clientCertificate,
      additionalHeaders: $extra.additionalHeaders,
    );
  }
}

class VerifyIdentityRoute extends GoRouteData with $VerifyIdentityRoute {
  static final $parentNavigatorKey = rootNavigatorKey;

  final String userId;
  const VerifyIdentityRoute({required this.userId});

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return NoTransitionPage(child: VerifyIdentityPage(userId: userId));
  }
}

class LoginToExistingAccountRoute extends GoRouteData
    with $LoginToExistingAccountRoute {
  static final $parentNavigatorKey = rootNavigatorKey;

  const LoginToExistingAccountRoute();

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
    final shouldRedirect = context
        .read<LocalStore>()
        .state
        .localUserData
        .isEmpty;
    if (shouldRedirect) {
      return "/auth";
    }
    return null;
  }

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return const NoTransitionPage(child: SelectAccountPage());
  }
}

class RestoringSessionRoute extends GoRouteData with $RestoringSessionRoute {
  static final $parentNavigatorKey = rootNavigatorKey;

  const RestoringSessionRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return NoTransitionPage(
      child: LoginTransitionPage(text: S.of(context)!.restoringSession),
    );
  }
}
