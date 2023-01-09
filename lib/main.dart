import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart' as cm;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl_standalone.dart';
import 'package:local_auth/local_auth.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/bloc/bloc_changes_observer.dart';
import 'package:paperless_mobile/core/bloc/connectivity_cubit.dart';
import 'package:paperless_mobile/core/bloc/paperless_server_information_cubit.dart';
import 'package:paperless_mobile/core/interceptor/dio_http_error_interceptor.dart';
import 'package:paperless_mobile/core/interceptor/language_header.interceptor.dart';
import 'package:paperless_mobile/core/repository/impl/correspondent_repository_impl.dart';
import 'package:paperless_mobile/core/repository/impl/document_type_repository_impl.dart';
import 'package:paperless_mobile/core/repository/impl/saved_view_repository_impl.dart';
import 'package:paperless_mobile/core/repository/impl/storage_path_repository_impl.dart';
import 'package:paperless_mobile/core/repository/impl/tag_repository_impl.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/core/repository/saved_view_repository.dart';
import 'package:paperless_mobile/core/repository/state/impl/correspondent_repository_state.dart';
import 'package:paperless_mobile/core/repository/state/impl/document_type_repository_state.dart';
import 'package:paperless_mobile/core/repository/state/impl/storage_path_repository_state.dart';
import 'package:paperless_mobile/core/repository/state/impl/tag_repository_state.dart';
import 'package:paperless_mobile/core/security/authentication_aware_dio_manager.dart';
import 'package:paperless_mobile/core/service/connectivity_status_service.dart';
import 'package:paperless_mobile/core/service/dio_file_service.dart';
import 'package:paperless_mobile/core/service/file_service.dart';
import 'package:paperless_mobile/core/store/local_vault.dart';
import 'package:paperless_mobile/features/app_intro/application_intro_slideshow.dart';
import 'package:paperless_mobile/features/home/view/home_page.dart';
import 'package:paperless_mobile/features/home/view/widget/verify_identity_page.dart';
import 'package:paperless_mobile/features/login/bloc/authentication_cubit.dart';
import 'package:paperless_mobile/features/login/bloc/authentication_state.dart';
import 'package:paperless_mobile/features/login/services/authentication_service.dart';
import 'package:paperless_mobile/features/login/view/login_page.dart';
import 'package:paperless_mobile/features/notifications/services/local_notification_service.dart';
import 'package:paperless_mobile/features/settings/bloc/application_settings_cubit.dart';
import 'package:paperless_mobile/features/settings/model/application_settings_state.dart';
import 'package:paperless_mobile/features/sharing/share_intent_queue.dart';
import 'package:paperless_mobile/features/tasks/cubit/task_status_cubit.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

void main() async {
  Bloc.observer = BlocChangesObserver();
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  await findSystemLocale();
  await LocalNotificationService.instance.initialize();

  // Initialize External dependencies
  final connectivity = Connectivity();
  final encryptedSharedPreferences = EncryptedSharedPreferences();
  final localAuthentication = LocalAuthentication();
  // Initialize other utility classes
  final connectivityStatusService = ConnectivityStatusServiceImpl(connectivity);
  final localVault = LocalVaultImpl(encryptedSharedPreferences);
  final localAuthService =
      LocalAuthenticationService(localVault, localAuthentication);

  final hiveDir = await getApplicationDocumentsDirectory();
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: hiveDir,
  );

  final appSettingsCubit = ApplicationSettingsCubit(localAuthService);
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  final languageHeaderInterceptor = LanguageHeaderInterceptor(
    appSettingsCubit.state.preferredLocaleSubtag,
  );
  // Required for self signed client certificates
  final dioWrapper = AuthenticationAwareDioManager([
    DioHttpErrorInterceptor(),
    PrettyDioLogger(
      compact: true,
      responseBody: false,
      responseHeader: false,
      request: false,
      requestBody: false,
      requestHeader: false,
    ),
    languageHeaderInterceptor,
  ]);

  // Initialize Paperless APIs
  final authApi = PaperlessAuthenticationApiImpl(dioWrapper.client);
  final documentsApi = PaperlessDocumentsApiImpl(dioWrapper.client);
  final labelsApi = PaperlessLabelApiImpl(dioWrapper.client);
  final statsApi = PaperlessServerStatsApiImpl(dioWrapper.client);
  final savedViewsApi = PaperlessSavedViewsApiImpl(dioWrapper.client);
  final tasksApi = PaperlessTasksApiImpl(dioWrapper.client);

  // Initialize Blocs/Cubits
  final connectivityCubit = ConnectivityCubit(connectivityStatusService);
  // Remove temporarily downloaded files.

  (await FileService.temporaryDirectory).deleteSync(recursive: true);
  // Load application settings and stored authentication data
  await connectivityCubit.initialize();

  // Create repositories
  final tagRepository = TagRepositoryImpl(labelsApi);
  final correspondentRepository = CorrespondentRepositoryImpl(labelsApi);
  final documentTypeRepository = DocumentTypeRepositoryImpl(labelsApi);
  final storagePathRepository = StoragePathRepositoryImpl(labelsApi);
  final savedViewRepository = SavedViewRepositoryImpl(savedViewsApi);

  //Create cubits/blocs
  final authCubit = AuthenticationCubit(
    localAuthService,
    authApi,
    dioWrapper,
  );
  await authCubit
      .restoreSessionState(appSettingsCubit.state.isLocalAuthenticationEnabled);

  if (authCubit.state.isAuthenticated) {
    final auth = authCubit.state.authentication!;
    dioWrapper.updateSettings(
      baseUrl: auth.serverUrl,
      authToken: auth.token,
      clientCertificate: auth.clientCertificate,
    );
  }

  //Update language header in interceptor on language change.
  appSettingsCubit.stream.listen((event) => languageHeaderInterceptor
      .preferredLocaleSubtag = event.preferredLocaleSubtag);
  runApp(
    MultiProvider(
      providers: [
        Provider<PaperlessAuthenticationApi>.value(value: authApi),
        Provider<PaperlessDocumentsApi>.value(value: documentsApi),
        Provider<PaperlessLabelsApi>.value(value: labelsApi),
        Provider<PaperlessServerStatsApi>.value(value: statsApi),
        Provider<PaperlessSavedViewsApi>.value(value: savedViewsApi),
        Provider<PaperlessTasksApi>.value(value: tasksApi),
        Provider<cm.CacheManager>(
          create: (context) => cm.CacheManager(
            cm.Config(
              'cacheKey',
              fileService: DioFileService(dioWrapper.client),
            ),
          ),
        ),
        Provider<LocalVault>.value(value: localVault),
        Provider<ConnectivityStatusService>.value(
          value: connectivityStatusService,
        ),
      ],
      child: MultiRepositoryProvider(
        providers: [
          RepositoryProvider<LabelRepository<Tag, TagRepositoryState>>.value(
            value: tagRepository,
          ),
          RepositoryProvider<
              LabelRepository<Correspondent,
                  CorrespondentRepositoryState>>.value(
            value: correspondentRepository,
          ),
          RepositoryProvider<
              LabelRepository<DocumentType, DocumentTypeRepositoryState>>.value(
            value: documentTypeRepository,
          ),
          RepositoryProvider<
              LabelRepository<StoragePath, StoragePathRepositoryState>>.value(
            value: storagePathRepository,
          ),
          RepositoryProvider<SavedViewRepository>.value(
            value: savedViewRepository,
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AuthenticationCubit>.value(value: authCubit),
            BlocProvider<ConnectivityCubit>.value(value: connectivityCubit),
            BlocProvider<ApplicationSettingsCubit>.value(
                value: appSettingsCubit),
          ],
          child: const PaperlessMobileEntrypoint(),
        ),
      ),
    ),
  );
}

class PaperlessMobileEntrypoint extends StatefulWidget {
  const PaperlessMobileEntrypoint({
    Key? key,
  }) : super(key: key);

  @override
  State<PaperlessMobileEntrypoint> createState() =>
      _PaperlessMobileEntrypointState();
}

class _PaperlessMobileEntrypointState extends State<PaperlessMobileEntrypoint> {
  final _lightTheme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    colorSchemeSeed: Colors.lightGreen,
    appBarTheme: const AppBarTheme(
      scrolledUnderElevation: 0.0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 16.0,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.lightGreen[50],
    ),
  );

  final _darkTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorSchemeSeed: Colors.lightGreen,
    appBarTheme: const AppBarTheme(
      scrolledUnderElevation: 0.0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 16.0,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.green[900],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => PaperlessServerInformationCubit(context.read()),
        ),
      ],
      child: BlocBuilder<ApplicationSettingsCubit, ApplicationSettingsState>(
        builder: (context, settings) {
          return MaterialApp(
            debugShowCheckedModeBanner: true,
            title: "Paperless Mobile",
            theme: _lightTheme.copyWith(
              listTileTheme: _lightTheme.listTileTheme
                  .copyWith(tileColor: Colors.transparent),
            ),
            darkTheme: _darkTheme.copyWith(
              listTileTheme: _darkTheme.listTileTheme
                  .copyWith(tileColor: Colors.transparent),
            ),
            themeMode: settings.preferredThemeMode,
            supportedLocales: S.delegate.supportedLocales,
            locale: Locale.fromSubtags(
              languageCode: settings.preferredLocaleSubtag,
            ),
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              FormBuilderLocalizations.delegate,
            ],
            home: const AuthenticationWrapper(),
          );
        },
      ),
    );
  }
}

class AuthenticationWrapper extends StatefulWidget {
  const AuthenticationWrapper({Key? key}) : super(key: key);

  @override
  State<AuthenticationWrapper> createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<AuthenticationWrapper> {
  @override
  void didChangeDependencies() {
    FlutterNativeSplash.remove();
    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
    // For sharing files coming from outside the app while the app is still opened
    ReceiveSharingIntent.getMediaStream()
        .listen(ShareIntentQueue.instance.addAll);
    // For sharing files coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialMedia()
        .then(ShareIntentQueue.instance.addAll);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthenticationCubit, AuthenticationState>(
      listener: (context, authState) {
        final bool showIntroSlider =
            authState.isAuthenticated && !authState.wasLoginStored;
        if (showIntroSlider) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ApplicationIntroSlideshow(),
              fullscreenDialog: true,
            ),
          );
        }
      },
      builder: (context, authentication) {
        if (authentication.isAuthenticated &&
            (authentication.wasLocalAuthenticationSuccessful ?? true)) {
          return BlocProvider(
            create: (context) =>
                TaskStatusCubit(context.read<PaperlessTasksApi>()),
            child: const HomePage(),
          );
        } else {
          if (authentication.wasLoginStored &&
              !(authentication.wasLocalAuthenticationSuccessful ?? false)) {
            return const VerifyIdentityPage();
          }
          return const LoginPage();
        }
      },
    );
  }
}
