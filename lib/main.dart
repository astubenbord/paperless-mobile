import 'dart:developer';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:intl/intl_standalone.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/bloc/bloc_changes_observer.dart';
import 'package:paperless_mobile/core/bloc/connectivity_cubit.dart';
import 'package:paperless_mobile/core/bloc/paperless_server_information_cubit.dart';
import 'package:paperless_mobile/core/global/constants.dart';
import 'package:paperless_mobile/core/global/http_self_signed_certificate_override.dart';
import 'package:paperless_mobile/core/logic/error_code_localization_mapper.dart';
import 'package:paperless_mobile/core/repository/impl/correspondent_repository_impl.dart';
import 'package:paperless_mobile/core/repository/impl/document_type_repository_impl.dart';
import 'package:paperless_mobile/core/repository/impl/saved_view_repository_impl.dart';
import 'package:paperless_mobile/core/repository/impl/storage_path_repository_impl.dart';
import 'package:paperless_mobile/core/repository/impl/tag_repository_impl.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/core/repository/saved_view_repository.dart';
import 'package:paperless_mobile/core/service/file_service.dart';
import 'package:paperless_mobile/core/store/local_vault.dart';
import 'package:paperless_mobile/di_initializer.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/app_intro/application_intro_slideshow.dart';
import 'package:paperless_mobile/features/document_upload/cubit/document_upload_cubit.dart';
import 'package:paperless_mobile/features/document_upload/view/document_upload_preparation_page.dart';
import 'package:paperless_mobile/features/home/view/home_page.dart';
import 'package:paperless_mobile/features/login/bloc/authentication_cubit.dart';
import 'package:paperless_mobile/features/login/services/authentication_service.dart';
import 'package:paperless_mobile/features/login/view/login_page.dart';
import 'package:paperless_mobile/features/settings/bloc/application_settings_cubit.dart';
import 'package:paperless_mobile/features/settings/model/application_settings_state.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:paperless_mobile/util.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

void main() async {
  Bloc.observer = BlocChangesObserver();
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  Intl.systemLocale = await findSystemLocale();

  // Required for self signed client certificates
  HttpOverrides.global = X509HttpOverrides();

  configureDependencies('prod');
  // Remove temporarily downloaded files.
  (await FileService.temporaryDirectory).deleteSync(recursive: true);
  kPackageInfo = await PackageInfo.fromPlatform();
  // Load application settings and stored authentication data
  await getIt<ConnectivityCubit>().initialize();
  await getIt<ApplicationSettingsCubit>().initialize();

  final authCubit = AuthenticationCubit(
    getIt<LocalVault>(),
    getIt<LocalAuthenticationService>(),
    getIt<PaperlessAuthenticationApi>(),
  );
  await authCubit.restoreSessionState();

  // Create repositories
  final LabelRepository<Tag> tagRepository =
      TagRepositoryImpl(getIt<PaperlessLabelsApi>());
  final LabelRepository<Correspondent> correspondentRepository =
      CorrespondentRepositoryImpl(getIt<PaperlessLabelsApi>());
  final LabelRepository<DocumentType> documentTypeRepository =
      DocumentTypeRepositoryImpl(getIt<PaperlessLabelsApi>());
  final LabelRepository<StoragePath> storagePathRepository =
      StoragePathRepositoryImpl(getIt<PaperlessLabelsApi>());
  final SavedViewRepository savedViewRepository =
      SavedViewRepositoryImpl(getIt<PaperlessSavedViewsApi>());

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: tagRepository),
        RepositoryProvider.value(value: correspondentRepository),
        RepositoryProvider.value(value: documentTypeRepository),
        RepositoryProvider.value(value: storagePathRepository),
        RepositoryProvider.value(value: savedViewRepository),
      ],
      child: PaperlessMobileEntrypoint(authenticationCubit: authCubit),
    ),
  );
}

class PaperlessMobileEntrypoint extends StatefulWidget {
  final AuthenticationCubit authenticationCubit;
  const PaperlessMobileEntrypoint({
    Key? key,
    required this.authenticationCubit,
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
        BlocProvider<ConnectivityCubit>.value(
          value: getIt<ConnectivityCubit>(),
        ),
        BlocProvider<PaperlessServerInformationCubit>.value(
          value: getIt<PaperlessServerInformationCubit>(),
        ),
        BlocProvider<ApplicationSettingsCubit>.value(
          value: getIt<ApplicationSettingsCubit>(),
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
            home: BlocProvider.value(
              value: widget.authenticationCubit,
              child: const AuthenticationWrapper(),
            ),
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
  bool isFileTypeSupported(SharedMediaFile file) {
    return supportedFileExtensions.contains(
      file.path.split('.').last.toLowerCase(),
    );
  }

  void handleReceivedFiles(List<SharedMediaFile> files) async {
    if (files.isEmpty) {
      return;
    }
    late final SharedMediaFile file;
    if (Platform.isIOS) {
      // Workaround for file not found on iOS: https://stackoverflow.com/a/72813212
      file = SharedMediaFile(
        files.first.path.replaceAll('file://', ''),
        files.first.thumbnail,
        files.first.duration,
        files.first.type,
      );
    } else {
      file = files.first;
    }

    if (!isFileTypeSupported(file)) {
      Fluttertoast.showToast(
        msg: translateError(context, ErrorCode.unsupportedFileFormat),
      );
      if (Platform.isAndroid) {
        // As stated in the docs, SystemNavigator.pop() is ignored on IOS to comply with HCI guidelines.
        await SystemNavigator.pop();
      }
      return;
    }
    final filename = extractFilenameFromPath(file.path);
    final bytes = File(file.path).readAsBytesSync();
    final success = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (BuildContext context) => DocumentUploadCubit(
            localVault: getIt<LocalVault>(),
            documentApi: getIt<PaperlessDocumentsApi>(),
            tagRepository: RepositoryProvider.of<LabelRepository<Tag>>(
              context,
            ),
            correspondentRepository:
                RepositoryProvider.of<LabelRepository<Correspondent>>(
              context,
            ),
            documentTypeRepository:
                RepositoryProvider.of<LabelRepository<DocumentType>>(
              context,
            ),
          ),
          child: DocumentUploadPreparationPage(
            fileBytes: bytes,
            filename: filename,
          ),
        ),
      ),
    );
    if (success) {
      SystemNavigator.pop();
    }
  }

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
    ReceiveSharingIntent.getMediaStream().listen(handleReceivedFiles);
    // For sharing files coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialMedia().then(handleReceivedFiles);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: true,
      left: false,
      right: false,
      bottom: false,
      child: BlocConsumer<AuthenticationCubit, AuthenticationState>(
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
          if (authentication.isAuthenticated) {
            return const HomePage();
          } else {
            if (authentication.wasLoginStored &&
                !(authentication.wasLocalAuthenticationSuccessful ?? false)) {
              return const BiometricAuthenticationPage();
            }
            return const LoginPage();
          }
        },
      ),
    );
  }
}

class BiometricAuthenticationPage extends StatelessWidget {
  const BiometricAuthenticationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "The app is locked!",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            "You can now either try to authenticate again or disconnect from the current server.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ).padded(),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                onPressed: () =>
                    BlocProvider.of<AuthenticationCubit>(context).logout(),
                child: const Text("Log out"),
              ),
              ElevatedButton(
                onPressed: () => BlocProvider.of<AuthenticationCubit>(context)
                    .restoreSessionState(),
                child: const Text("Authenticate"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
