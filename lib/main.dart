import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl_standalone.dart';
import 'package:local_auth/local_auth.dart';
import 'package:logger/logger.dart' as l;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/accessibility/accessible_page.dart';
import 'package:paperless_mobile/core/global/constants.dart';
import 'package:paperless_mobile/core/bloc/connectivity_cubit.dart';
import 'package:paperless_mobile/core/bloc/my_bloc_observer.dart';
import 'package:paperless_mobile/core/database/hive/hive_config.dart';
import 'package:paperless_mobile/core/database/hive/hive_extensions.dart';
import 'package:paperless_mobile/core/database/hive/hive_initialization.dart';
import 'package:paperless_mobile/core/model/server_message_exception.dart';
import 'package:paperless_mobile/core/factory/paperless_api_factory.dart';
import 'package:paperless_mobile/core/factory/paperless_api_factory_impl.dart';
import 'package:paperless_mobile/core/interceptor/language_header.interceptor.dart';
import 'package:paperless_mobile/core/security/session_manager_impl.dart';
import 'package:paperless_mobile/features/logging/data/formatted_printer.dart';
import 'package:paperless_mobile/core/logging/logger.dart';
import 'package:paperless_mobile/features/logging/data/mirrored_file_output.dart';
import 'package:paperless_mobile/core/notifier/document_changed_notifier.dart';
import 'package:paperless_mobile/core/security/session_manager.dart';
import 'package:paperless_mobile/core/service/connectivity_status_service.dart';
import 'package:paperless_mobile/core/service/file_service.dart';
import 'package:paperless_mobile/features/login/cubit/authentication_cubit.dart';
import 'package:paperless_mobile/features/login/services/authentication_service.dart';
import 'package:paperless_mobile/features/notifications/services/local_notification_service.dart';
import 'package:paperless_mobile/core/widgets/global_settings_builder.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/routing/navigation_keys.dart';
import 'package:paperless_mobile/routing/routes/landing_route.dart';
import 'package:paperless_mobile/routing/routes/shells/authenticated_route.dart';
import 'package:paperless_mobile/routing/routes/add_account_route.dart';
import 'package:paperless_mobile/routing/routes/app_logs_route.dart';
import 'package:paperless_mobile/routing/routes/changelog_route.dart';
import 'package:paperless_mobile/routing/routes/logging_out_route.dart';
import 'package:paperless_mobile/routing/routes/login_route.dart';
import 'package:paperless_mobile/core/theme.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

Map<String, Future<void> Function()> _migrations = {
  '3.0.1': () async {
    // Remove all stored data due to updates in schema
    await Future.wait([
      for (var box in HiveBoxes.all) Hive.deleteBoxFromDisk(box),
    ]);
  },
};

Future<void> performMigrations() async {
  final sp = await SharedPreferences.getInstance();
  final currentVersion = packageInfo.version;
  final migrationExists = _migrations.containsKey(currentVersion);
  if (!migrationExists) {
    return;
  }
  final migrationProcedure = _migrations[currentVersion]!;
  final performedMigrations = sp.getStringList("performed_migrations") ?? [];
  final requiresMigrationForCurrentVersion =
      !performedMigrations.contains(currentVersion);
  if (requiresMigrationForCurrentVersion) {
    logger.fd(
      "Applying migration scripts for version $currentVersion",
      className: "",
      methodName: "performMigrations",
    );
    await migrationProcedure();
    await sp.setStringList(
      'performed_migrations',
      [...performedMigrations, currentVersion],
    );
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
  runZonedGuarded(() async {
    final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
    final hiveDirectory = await getApplicationDocumentsDirectory();
    final defaultLocale = defaultPreferredLocale.languageCode;
    await initializeDefaultParameters();
    await initHive(hiveDirectory, defaultLocale);
    await performMigrations();

    final connectivityStatusService = ConnectivityStatusServiceImpl(
      Connectivity(),
    );
    final localAuthService = LocalAuthenticationService(
      LocalAuthentication(),
    );

    HydratedBloc.storage = await HydratedStorage.build(
      storageDirectory: HydratedStorageDirectory(
          (await getApplicationDocumentsDirectory()).path),
    );

    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

    final languageHeaderInterceptor = LanguageHeaderInterceptor(
      () => Hive.globalSettingsBox.getValue()!.preferredLocaleSubtag,
    );
    // Manages security context, required for self signed client certificates
    final SessionManager sessionManager = SessionManagerImpl([
      PrettyDioLogger(
        compact: true,
        responseBody: false,
        responseHeader: false,
        request: false,
        requestBody: false,
        requestHeader: false,
        logPrint: (object) => logger.t,
      ),
      languageHeaderInterceptor,
    ]);

    final localNotificationService = LocalNotificationService();
    await localNotificationService.initialize();

    final apiFactory = PaperlessApiFactoryImpl(sessionManager);
    final authenticationCubit = AuthenticationCubit(
      localAuthService,
      apiFactory,
      sessionManager,
      connectivityStatusService,
      localNotificationService,
    );
    runApp(
      AppEntrypoint(
        sessionManager: sessionManager,
        apiFactory: apiFactory,
        authenticationCubit: authenticationCubit,
        connectivityStatusService: connectivityStatusService,
        localNotificationService: localNotificationService,
        localAuthService: localAuthService,
      ),
    );
  }, (error, stackTrace) {
    if (error is StateError &&
        error.message.contains("Cannot emit new states")) {
      return;
    }
    // Catches all unexpected/uncaught errors and prints them to the console.
    final message = switch (error) {
      PaperlessApiException e => e.details ?? error.toString(),
      ServerMessageException e => e.message,
      _ => null
    };
    logger.fe(
      "An unexpected error occurred ${message != null ? "- $message" : ""}",
      error: message == null ? error : null,
      methodName: "main",
      stackTrace: stackTrace,
    );
  });
}

class AppEntrypoint extends StatelessWidget {
  final PaperlessApiFactory apiFactory;
  final AuthenticationCubit authenticationCubit;
  final ConnectivityStatusService connectivityStatusService;
  final LocalNotificationService localNotificationService;
  final LocalAuthenticationService localAuthService;
  final SessionManager sessionManager;

  const AppEntrypoint({
    super.key,
    required this.apiFactory,
    required this.authenticationCubit,
    required this.connectivityStatusService,
    required this.localNotificationService,
    required this.localAuthService,
    required this.sessionManager,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: DocumentChangedNotifier()),
        Provider.value(value: authenticationCubit),
        Provider.value(
          value: ConnectivityCubit(connectivityStatusService)..initialize(),
        ),
        ChangeNotifierProvider.value(value: sessionManager),
        Provider.value(value: connectivityStatusService),
        Provider.value(value: localNotificationService),
        Provider.value(value: localAuthService),
      ],
      child: GoRouterShell(
        apiFactory: apiFactory,
      ),
    );
  }
}

class GoRouterShell extends StatefulWidget {
  final PaperlessApiFactory apiFactory;

  const GoRouterShell({
    super.key,
    required this.apiFactory,
  });

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
      await context.read<AuthenticationCubit>().restoreSession();
      FlutterNativeSplash.remove();
    });
  }

  /// Activates the highest supported refresh rate on the device.
  Future<void> _setOptimalDisplayMode() async {
    final List<DisplayMode> supported = await FlutterDisplayMode.supported;
    final DisplayMode active = await FlutterDisplayMode.active;

    final List<DisplayMode> sameResolution = supported
        .where((m) => m.width == active.width && m.height == active.height)
        .toList()
      ..sort((a, b) => b.refreshRate.compareTo(a.refreshRate));

    final DisplayMode mostOptimalMode =
        sameResolution.isNotEmpty ? sameResolution.first : active;
    logger.fi('Setting refresh rate to ${mostOptimalMode.refreshRate}');

    await FlutterDisplayMode.setPreferredMode(mostOptimalMode);
  }

  late final _router = GoRouter(
    debugLogDiagnostics: kDebugMode,
    initialLocation: "/login",
    routes: [
      ShellRoute(
        pageBuilder: (context, state, child) {
          return accessiblePlatformPage(
            child: Provider.value(
              value: widget.apiFactory,
              child: BlocListener<AuthenticationCubit, AuthenticationState>(
                listener: (context, state) {
                  switch (state) {
                    case UnauthenticatedState(
                        redirectToAccountSelection: var shouldRedirect
                      ):
                      if (shouldRedirect) {
                        const LoginToExistingAccountRoute().go(context);
                      } else {
                        const LoginRoute().go(context);
                      }
                      break;
                    case RestoringSessionState():
                      const RestoringSessionRoute().go(context);
                      break;
                    case VerifyIdentityState(userId: var userId):
                      VerifyIdentityRoute(userId: userId).go(context);
                      break;
                    case SwitchingAccountsState():
                      const SwitchingAccountsRoute().push(context);
                      break;
                    case AuthenticatedState():
                      const LandingRoute().go(context);
                      break;
                    case AuthenticatingState state:
                      AuthenticatingRoute(state.currentStage.name)
                          .push(context);
                      break;
                    case LoggingOutState():
                      const LoggingOutRoute().go(context);
                      break;
                    case AuthenticationErrorState():
                      if (context.canPop()) {
                        context.pop();
                      }
                      break;
                  }
                },
                child: child,
              ),
            ),
          );
        },
        navigatorKey: rootNavigatorKey,
        routes: [
          $loginRoute,
          $loggingOutRoute,
          $addAccountRoute,
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
                    systemNavigationBarColor:
                        Theme.of(context).colorScheme.surface,
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
                Locale('nl'),
                Locale('pl'),
                Locale('ro'),
                Locale('ru'),
                Locale('tr'),
                Locale('it'),
              ],
              localeResolutionCallback: (locale, supportedLocales) {
                if (locale == null) {
                  return supportedLocales.first;
                }

                final exactMatch = supportedLocales
                    .where((element) =>
                        element.languageCode == locale.languageCode &&
                        element.countryCode == locale.countryCode)
                    .toList();
                if (exactMatch.isNotEmpty) {
                  return exactMatch.first;
                }
                final superLanguageMatch = supportedLocales
                    .where((element) =>
                        element.languageCode == locale.languageCode)
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
