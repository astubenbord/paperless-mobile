import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import 'package:intl/intl_standalone.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/bloc/bloc_changes_observer.dart';
import 'package:paperless_mobile/core/bloc/connectivity_cubit.dart';
import 'package:paperless_mobile/features/labels/bloc/global_state_bloc_provider.dart';
import 'package:paperless_mobile/core/bloc/paperless_server_information_cubit.dart';
import 'package:paperless_mobile/core/global/constants.dart';
import 'package:paperless_mobile/core/global/http_self_signed_certificate_override.dart';
import 'package:paperless_mobile/core/logic/error_code_localization_mapper.dart';
import 'package:paperless_mobile/core/service/file_service.dart';
import 'package:paperless_mobile/di_initializer.dart';
import 'package:paperless_mobile/features/app_intro/application_intro_slideshow.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/home/view/home_page.dart';
import 'package:paperless_mobile/features/login/bloc/authentication_cubit.dart';
import 'package:paperless_mobile/features/login/view/login_page.dart';
import 'package:paperless_mobile/features/scan/bloc/document_scanner_cubit.dart';
import 'package:paperless_mobile/features/scan/view/document_upload_page.dart';
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

  configureDependencies();
  // Remove temporarily downloaded files.
  (await FileService.temporaryDirectory).deleteSync(recursive: true);
  kPackageInfo = await PackageInfo.fromPlatform();
  // Load application settings and stored authentication data
  getIt<ConnectivityCubit>().initialize();
  await getIt<ApplicationSettingsCubit>().initialize();
  await getIt<AuthenticationCubit>().initialize();

  // Preload asset images
  // WARNING: This seems to bloat up the app up to almost 200mb!
  // await Future.forEach<AssetImage>(
  //   AssetImages.values.map((e) => e.image),
  //   (img) => loadImage(img),
  // );

  runApp(const PaperlessMobileEntrypoint());
}

class PaperlessMobileEntrypoint extends StatefulWidget {
  const PaperlessMobileEntrypoint({Key? key}) : super(key: key);

  @override
  State<PaperlessMobileEntrypoint> createState() =>
      _PaperlessMobileEntrypointState();
}

class _PaperlessMobileEntrypointState extends State<PaperlessMobileEntrypoint> {
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
              Locale('cs'),
            ],
            locale: Locale.fromSubtags(
                languageCode: settings.preferredLocaleSubtag),
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
      // Workaround: https://stackoverflow.com/a/72813212
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GlobalStateBlocProvider(
          additionalProviders: [
            BlocProvider.value(value: getIt<DocumentScannerCubit>()),
          ],
          child: DocumentUploadPage(
            fileBytes: bytes,
            afterUpload: SystemNavigator.pop,
            filename: filename,
          ),
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    FlutterNativeSplash.remove();
    super.didChangeDependencies();
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
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
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
            return GlobalStateBlocProvider(
              additionalProviders: [
                BlocProvider.value(value: getIt<DocumentsCubit>()),
              ],
              child: const HomePage(),
            );
          } else {
            return const LoginPage();
          }
        },
      ),
    );
  }
}
