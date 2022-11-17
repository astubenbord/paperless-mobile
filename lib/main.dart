import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import 'package:intl/intl_standalone.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:paperless_mobile/core/bloc/connectivity_cubit.dart';
import 'package:paperless_mobile/core/bloc/label_bloc_provider.dart';
import 'package:paperless_mobile/core/bloc/paperless_server_information_cubit.dart';
import 'package:paperless_mobile/core/global/asset_images.dart';
import 'package:paperless_mobile/core/global/constants.dart';
import 'package:paperless_mobile/core/global/http_self_signed_certificate_override.dart';
import 'package:paperless_mobile/core/model/error_message.dart';
import 'package:paperless_mobile/core/service/file_service.dart';
import 'package:paperless_mobile/di_initializer.dart';
import 'package:paperless_mobile/features/app_intro/application_intro_slideshow.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/home/view/home_page.dart';
import 'package:paperless_mobile/features/login/bloc/authentication_cubit.dart';
import 'package:paperless_mobile/features/login/view/login_page.dart';
import 'package:paperless_mobile/features/scan/view/document_upload_page.dart';
import 'package:paperless_mobile/features/settings/bloc/application_settings_cubit.dart';
import 'package:paperless_mobile/features/settings/model/application_settings_state.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:paperless_mobile/util.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  Intl.systemLocale = await findSystemLocale();

  // Required for self signed client certificates
  HttpOverrides.global = X509HttpOverrides();

  configureDependencies();
  // Remove temporarily downloaded files.
  (await FileService.temporaryDirectory).deleteSync(recursive: true);
  kPackageInfo = await PackageInfo.fromPlatform();
  // Load application settings and stored authentication data
  getIt<ConnectivityCubit>().initialize();
  await getIt<ApplicationSettingsCubit>().initialize();
  await getIt<AuthenticationCubit>().initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<ConnectivityCubit>()),
        BlocProvider.value(value: getIt<AuthenticationCubit>()),
        BlocProvider.value(value: getIt<PaperlessServerInformationCubit>()),
        BlocProvider.value(value: getIt<ApplicationSettingsCubit>()),
      ],
      child: BlocBuilder<ApplicationSettingsCubit, ApplicationSettingsState>(
        builder: (context, settings) {
          return MaterialApp(
            debugShowCheckedModeBanner: true,
            title: "Paperless Mobile",
            theme: ThemeData(
              brightness: Brightness.light,
              useMaterial3: true,
              colorSchemeSeed: Colors.lightGreen,
              appBarTheme: const AppBarTheme(
                scrolledUnderElevation: 0.0,
              ),
              inputDecorationTheme: const InputDecorationTheme(
                border: OutlineInputBorder(),
              ),
              chipTheme: ChipThemeData(
                backgroundColor: Colors.lightGreen[50],
              ),
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              useMaterial3: true,
              colorSchemeSeed: Colors.lightGreen,
              //primarySwatch: Colors.green,
              appBarTheme: const AppBarTheme(
                scrolledUnderElevation: 0.0,
              ),
              inputDecorationTheme: const InputDecorationTheme(
                border: OutlineInputBorder(),
              ),
              chipTheme: ChipThemeData(
                backgroundColor: Colors.green[900],
              ),
            ),
            themeMode: settings.preferredThemeMode,
            supportedLocales: const [
              Locale('en'), // Default if system locale is not available
              Locale('de'),
            ],
            locale: Locale.fromSubtags(
                languageCode: settings.preferredLocaleSubtag),
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              FormBuilderLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
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
  bool isFileTypeSupported(SharedMediaFile file) {
    return supportedFileExtensions.contains(file.path.split('.').last);
  }

  void handleReceivedFiles(List<SharedMediaFile> files) async {
    if (files.isEmpty) {
      return;
    }
    if (!isFileTypeSupported(files.first)) {
      showError(context, const ErrorMessage(ErrorCode.unsupportedFileFormat));
      await Future.delayed(
        const Duration(seconds: 2),
        () => SystemNavigator.pop(),
      );
    }
    final bytes = File(files.first.path).readAsBytesSync();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: getIt<DocumentsCubit>(),
          child: LabelBlocProvider(
            child: DocumentUploadPage(
              fileBytes: bytes,
              afterUpload: () => SystemNavigator.pop(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // For sharing files coming from outside the app while the app is still opened
    ReceiveSharingIntent.getMediaStream().listen(handleReceivedFiles);
    // For sharing files coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialMedia().then(handleReceivedFiles);
  }

  @override
  void didChangeDependencies() {
    FlutterNativeSplash.remove();
    for (var element in AssetImages.values) {
      element.load(context);
    }
    super.didChangeDependencies();
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
            for (final img in AssetImages.values) {
              img.load(context);
            }
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
            return const LabelBlocProvider(
              child: HomePage(),
            );
          } else {
            return const LoginPage();
          }
        },
      ),
    );
  }
}
