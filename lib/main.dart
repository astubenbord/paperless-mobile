import 'dart:async';
import 'dart:io';

import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl_standalone.dart';
import 'package:local_auth/local_auth.dart';
import 'package:logger/logger.dart' as l;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:paperless_mobile/accessibility/accessible_page.dart';
import 'package:paperless_mobile/api/paperless_api.dart';
import 'package:paperless_mobile/constants.dart';
import 'package:paperless_mobile/core/bloc/connectivity_cubit.dart';
import 'package:paperless_mobile/core/bloc/my_bloc_observer.dart';
import 'package:paperless_mobile/core/exception/server_message_exception.dart';
import 'package:paperless_mobile/core/interceptor/language_header.interceptor.dart';
import 'package:paperless_mobile/core/security/session_manager.dart';
import 'package:paperless_mobile/core/security/session_manager_impl.dart';
import 'package:paperless_mobile/core/security/system_http_proxy.dart';
import 'package:paperless_mobile/core/service/connectivity_status_service.dart';
import 'package:paperless_mobile/core/service/file_service.dart';
import 'package:paperless_mobile/core/store/bloc/global_settings_builder.dart';
import 'package:paperless_mobile/core/store/encrypted_local_store.dart';
import 'package:paperless_mobile/core/store/encrypted_local_store_secure_storage_impl.dart';
import 'package:paperless_mobile/core/store/local_store.dart';
import 'package:paperless_mobile/features/error_widget/error_fallback_card.dart';
import 'package:paperless_mobile/features/logging/data/formatted_printer.dart';
import 'package:paperless_mobile/features/logging/data/logger.dart';
import 'package:paperless_mobile/features/logging/data/mirrored_file_output.dart';
import 'package:paperless_mobile/features/login/cubit/authentication_cubit.dart';
import 'package:paperless_mobile/features/login/services/authentication_service.dart';
import 'package:paperless_mobile/features/notifications/services/local_notification_service.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/helpers/message_helpers.dart';
import 'package:paperless_mobile/routing/navigation_keys.dart';
import 'package:paperless_mobile/routing/routes/app_logs_route.dart';
import 'package:paperless_mobile/routing/routes/auth_route.dart';
import 'package:paperless_mobile/routing/routes/changelog_route.dart';
import 'package:paperless_mobile/routing/routes/landing_route.dart';
import 'package:paperless_mobile/routing/routes/logging_out_route.dart';
import 'package:paperless_mobile/routing/routes/shells/authenticated_route.dart';
import 'package:paperless_mobile/theme.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:provider/provider.dart';

Locale get defaultPreferredLocale {
  final deviceLocale = _stringToLocale(Platform.localeName);
  if (S.supportedLocales.contains(deviceLocale)) {
    return deviceLocale;
  } else if (S.supportedLocales
      .map((e) => e.languageCode)
      .contains(deviceLocale.languageCode)) {
    return Locale(deviceLocale.languageCode);
  } else {
    return const Locale('en');
  }
}

Future<void> initializeDefaultParameters() async {
  Bloc.observer = MyBlocObserver();
  await FileService.instance.initialize();
  logger = l.Logger(
    output: MirroredFileOutput(),
    printer: FormattedPrinter(),
    level: l.Level.trace,
    filter: l.ProductionFilter(),
  );

  packageInfo = await PackageInfo.fromPlatform();

  if (Platform.isAndroid) {
    androidInfo = await DeviceInfoPlugin().androidInfo;
  }
  if (Platform.isIOS) {
    iosInfo = await DeviceInfoPlugin().iosInfo;
  }

  await findSystemLocale();
}

void main() async {
  runZonedGuarded(
    () async {
      ErrorWidget.builder = (errorDetails) =>
          ErrorFallbackCard(errorDetails: errorDetails);
      final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
      final defaultLocale = defaultPreferredLocale.languageCode;
      await initializeDefaultParameters();
      await installSystemHttpProxy();
      CachedQuery.instance.configFlutter(
        config: GlobalQueryConfig(
          refetchOnConnection: true,
          refetchOnResume: true,
        ),
      );
      final connectivityStatusService = ConnectivityStatusServiceImpl(
        Connectivity(),
      );
      final localAuthService = LocalAuthenticationService(
        LocalAuthentication(),
      );

      // final encryptionPassword = String.fromEnvironment(
      //   'HIVE_ENCRYPTION_CIPHER',
      //   defaultValue: 'debug_encryption_password',
      // );

      // final encodedEncryptionPassword = sha256
      //     .convert(utf8.encode(encryptionPassword))
      //     .bytes;

      HydratedBloc.storage = await HydratedStorage.build(
        storageDirectory: HydratedStorageDirectory(
          (await getApplicationDocumentsDirectory()).path,
        ),
      );
      final FlutterSecureStorage secureStorage = FlutterSecureStorage();
      FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

      final localStore = LocalStore(defaultLocale);
      final languageHeaderInterceptor = LanguageHeaderInterceptor(() {
        return localStore.state.globalSettings.preferredLocaleSubtag;
      });

      // Manages security context, required for self signed client certificates
      final SessionManager sessionManager = SessionManagerImpl([
        PrettyDioLogger(
          enabled: false,
          compact: true,
          responseBody: true,
          responseHeader: true,
          request: true,
          requestBody: true,
          requestHeader: true,
        ),
        languageHeaderInterceptor,
      ]);

      final localNotificationService = LocalNotificationService();
      final EncryptedLocalStore encryptedLocalStore =
          EncryptedLocalStoreSecureStorageImpl(secureStorage);
      await localNotificationService.initialize();

      final userApi = PaperlessUserApiImpl(sessionManager.client);
      final authenticationCubit = AuthenticationCubit(
        userApi,
        sessionManager,
        connectivityStatusService,
        localAuthService,
        localNotificationService,
        localStore,
        encryptedLocalStore,
      );

      runApp(
        AppEntrypoint(
          sessionManager: sessionManager,
          authenticationCubit: authenticationCubit,
          connectivityStatusService: connectivityStatusService,
          localNotificationService: localNotificationService,
          localAuthService: localAuthService,
          localStore: localStore,
          encryptedLocalStore: encryptedLocalStore,
        ),
      );
    },
    (error, stackTrace) {
      if (error is StateError &&
          error.message.contains("Cannot emit new states")) {
        return;
      }
      // Catches all unexpected/uncaught errors and prints them to the console.
      final message = switch (error) {
        PaperlessApiException e => e.details ?? error.toString(),
        ServerMessageException e => e.message,
        _ => null,
      };
      logger.fe(
        "An unexpected error occurred ${message != null ? "- $message" : ""}",
        error: message == null ? error : null,
        methodName: "main",
        stackTrace: stackTrace,
      );
    },
  );
}

class AppEntrypoint extends StatelessWidget {
  final LocalStore localStore;
  final EncryptedLocalStore encryptedLocalStore;
  final AuthenticationCubit authenticationCubit;
  final ConnectivityStatusService connectivityStatusService;
  final LocalNotificationService localNotificationService;
  final LocalAuthenticationService localAuthService;
  final SessionManager sessionManager;

  const AppEntrypoint({
    super.key,
    required this.localStore,
    required this.authenticationCubit,
    required this.connectivityStatusService,
    required this.localNotificationService,
    required this.localAuthService,
    required this.sessionManager,
    required this.encryptedLocalStore,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<PaperlessAuthenticationApi>(
          create: (context) =>
              PaperlessAuthenticationApiImpl(sessionManager.client),
        ),
        Provider.value(value: localStore),
        Provider.value(value: encryptedLocalStore),
        Provider.value(value: authenticationCubit),
        Provider.value(
          value: ConnectivityCubit(connectivityStatusService)..initialize(),
        ),
        ChangeNotifierProvider.value(value: sessionManager),
        Provider.value(value: connectivityStatusService),
        Provider.value(value: localNotificationService),
        Provider.value(value: localAuthService),
      ],
      child: GoRouterShell(),
    );
  }
}

class GoRouterShell extends StatefulWidget {
  const GoRouterShell({super.key});

  @override
  State<GoRouterShell> createState() => _GoRouterShellState();
}

class _GoRouterShellState extends State<GoRouterShell> {
  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      _setOptimalDisplayMode();
    }
    initializeDateFormatting();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<AuthenticationCubit>().restoreSession();
      FlutterNativeSplash.remove();
    });
  }

  /// Activates the highest supported refresh rate on the device.
  Future<void> _setOptimalDisplayMode() async {
    final List<DisplayMode> supported = await FlutterDisplayMode.supported;
    final DisplayMode active = await FlutterDisplayMode.active;

    final List<DisplayMode> sameResolution =
        supported
            .where((m) => m.width == active.width && m.height == active.height)
            .toList()
          ..sort((a, b) => b.refreshRate.compareTo(a.refreshRate));

    final DisplayMode mostOptimalMode = sameResolution.isNotEmpty
        ? sameResolution.first
        : active;
    logger.fi(
      'Setting refresh rate to ${mostOptimalMode.refreshRate}',
      className: runtimeType.toString(),
      methodName: '_setOptimalDisplayMode',
    );

    await FlutterDisplayMode.setPreferredMode(mostOptimalMode);
  }

  late final _router = GoRouter(
    debugLogDiagnostics: kDebugMode,
    initialLocation: "/auth",
    onException: (context, state, router) {
      // content:// and file:// URIs from file-open intents are
      // not app routes. GoRouter sees them as deep links. so we ignore them and
      // fall back to the initial location. The actual file is received
      // separately through the share intent listener.
      router.go('/auth');
    },
    routes: [
      ShellRoute(
        pageBuilder: (context, state, child) {
          return accessiblePlatformPage(
            child: BlocListener<AuthenticationCubit, AuthenticationState>(
              listener: (context, state) {
                switch (state) {
                  case Unauthenticated(
                    redirectToAccountSelection: var shouldRedirect,
                  ):
                    if (shouldRedirect) {
                      const LoginToExistingAccountRoute().go(context);
                    } else {
                      const AuthRoute().go(context);
                    }
                    break;
                  case RestoringSession():
                    const RestoringSessionRoute().go(context);
                    break;
                  case VerifyingIdentity(:final userId):
                    VerifyIdentityRoute(
                      userId: userId,
                    ).pushReplacement(context);
                    break;
                  case SwitchingAccounts():
                    const SwitchingAccountsRoute().go(context);
                    break;
                  case Authenticated():
                    const LandingRoute().go(context);
                    break;
                  case LoggingOutState():
                    const LoggingOutRoute().go(context);
                    break;
                  case AuthenticationError error:
                    showGenericError(context, error.error);
                    context.pop();
                    break;
                  case ConnectionFailure():
                    showSnackBar(
                      context,
                      S.of(context)!.couldNotEstablishConnectionToTheServer,
                    );
                    LoginToExistingAccountRoute().go(context);
                  default:
                    break;
                }
              },
              child: child,
            ),
          );
        },
        navigatorKey: rootNavigatorKey,
        routes: [
          $authRoute,
          $loggingOutRoute,
          $changelogRoute,
          $appLogsRoute,
          $authenticatedRoute,
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return GlobalSettingsBuilder(
      builder: (context, settings) {
        final locale = _stringToLocale(settings.preferredLocaleSubtag);
        return DynamicColorBuilder(
          builder: (lightDynamic, darkDynamic) {
            return MaterialApp.router(
              builder: (context, child) {
                return AnnotatedRegion<SystemUiOverlayStyle>(
                  value: buildOverlayStyle(
                    Theme.of(context),
                    systemNavigationBarColor: Theme.of(
                      context,
                    ).colorScheme.surface,
                  ),
                  child: child!,
                );
              },
              routerConfig: _router,
              debugShowCheckedModeBanner: false,
              title: "Paperless Mobile",
              theme: buildTheme(
                brightness: Brightness.light,
                dynamicScheme: lightDynamic,
                preferredColorScheme: settings.preferredColorSchemeOption,
              ),
              darkTheme: buildTheme(
                brightness: Brightness.dark,
                dynamicScheme: darkDynamic,
                preferredColorScheme: settings.preferredColorSchemeOption,
              ),
              themeMode: settings.preferredThemeMode,
              supportedLocales: const [
                Locale('en'),
                Locale('de'),
                Locale('en', 'GB'),
                Locale('ca'),
                Locale('cs'),
                Locale('es'),
                Locale('fr'),
                Locale('pl'),
                Locale('ru'),
                Locale('tr'),
                Locale('it'),
                Locale('sl'),
              ],
              localeResolutionCallback: (locale, supportedLocales) {
                if (locale == null) {
                  return supportedLocales.first;
                }

                final exactMatch = supportedLocales
                    .where(
                      (element) =>
                          element.languageCode == locale.languageCode &&
                          element.countryCode == locale.countryCode,
                    )
                    .toList();
                if (exactMatch.isNotEmpty) {
                  return exactMatch.first;
                }
                final superLanguageMatch = supportedLocales
                    .where(
                      (element) => element.languageCode == locale.languageCode,
                    )
                    .toList();
                if (superLanguageMatch.isNotEmpty) {
                  return superLanguageMatch.first;
                }
                return supportedLocales.first;
              },
              locale: locale,
              localizationsDelegates: S.localizationsDelegates,
            );
          },
        );
      },
    );
  }
}

Locale _stringToLocale(String code) {
  final codes = code.split("_");
  final languageCode = codes[0];
  final countryCode = codes.length > 1 ? codes[1] : null;
  return Locale(languageCode, countryCode);
}
