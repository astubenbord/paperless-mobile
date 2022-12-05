import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/bloc/connectivity_cubit.dart';
import 'package:paperless_mobile/core/service/connectivity_status.service.dart';
import 'package:paperless_mobile/core/store/local_vault.dart';
import 'package:paperless_mobile/di_initializer.dart';
import 'package:paperless_mobile/di_test_mocks.mocks.dart';
import 'package:paperless_mobile/features/login/bloc/authentication_cubit.dart';
import 'package:paperless_mobile/features/settings/bloc/application_settings_cubit.dart';
import 'package:paperless_mobile/features/settings/model/application_settings_state.dart';
import 'package:paperless_mobile/features/settings/model/view_type.dart';

import 'src/framework.dart';

void main() async {
  final t = await initializeTestingFramework(languageCode: 'de');

  const testServerUrl = 'https://example.com';
  const testUsername = 'user';
  const testPassword = 'pass';

  final serverAddressField = find.byKey(const ValueKey('login-server-address'));
  final usernameField = find.byKey(const ValueKey('login-username'));
  final passwordField = find.byKey(const ValueKey('login-password'));
  final loginBtn = find.byKey(const ValueKey('login-login-button'));

  testWidgets('Test successful login flow', (WidgetTester tester) async {
    await initAndLaunchTestApp(tester, () async {
      // Initialize dat for mocked classes
      when((getIt<ConnectivityStatusService>()).connectivityChanges())
          .thenAnswer((i) => Stream.value(true));
      when((getIt<LocalVault>() as MockLocalVault)
              .loadAuthenticationInformation())
          .thenAnswer((realInvocation) async => null);
      when((getIt<LocalVault>() as MockLocalVault).loadApplicationSettings())
          .thenAnswer((realInvocation) async => ApplicationSettingsState(
                preferredLocaleSubtag: 'en',
                preferredThemeMode: ThemeMode.light,
                isLocalAuthenticationEnabled: false,
                preferredViewType: ViewType.list,
                showInboxOnStartup: false,
              ));
      when(getIt<PaperlessAuthenticationApi>().login(
        username: testUsername,
        password: testPassword,
      )).thenAnswer((i) => Future.value("eyTestToken"));

      await getIt<ConnectivityCubit>().initialize();
      await getIt<ApplicationSettingsCubit>().initialize();
      await getIt<AuthenticationCubit>().initialize();
    });

    // Mocked classes

    await t.binding.waitUntilFirstFrameRasterized;
    await tester.pumpAndSettle();

    await tester.enterText(serverAddressField, testServerUrl);
    await tester.pumpAndSettle();

    await tester.enterText(usernameField, testUsername);
    await tester.pumpAndSettle();

    await tester.enterText(passwordField, testPassword);

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    await tester.tap(loginBtn);

    verify(getIt<PaperlessAuthenticationApi>().login(
      username: testUsername,
      password: testPassword,
    )).called(1);
  });

  testWidgets('Test login validation missing password',
      (WidgetTester tester) async {
    await initAndLaunchTestApp(tester, () async {
      when((getIt<ConnectivityStatusService>() as MockConnectivityStatusService)
              .connectivityChanges())
          .thenAnswer((i) => Stream.value(true));
      when((getIt<LocalVault>() as MockLocalVault)
              .loadAuthenticationInformation())
          .thenAnswer((realInvocation) async => null);

      when((getIt<LocalVault>() as MockLocalVault).loadApplicationSettings())
          .thenAnswer((realInvocation) async => ApplicationSettingsState(
                preferredLocaleSubtag: 'en',
                preferredThemeMode: ThemeMode.light,
                isLocalAuthenticationEnabled: false,
                preferredViewType: ViewType.list,
                showInboxOnStartup: false,
              ));

      await getIt<ConnectivityCubit>().initialize();
      await getIt<ApplicationSettingsCubit>().initialize();
      await getIt<AuthenticationCubit>().initialize();
    });
    // Mocked classes

    // Initialize dat for mocked classes

    await t.binding.waitUntilFirstFrameRasterized;
    await tester.pumpAndSettle();

    await tester.enterText(serverAddressField, testServerUrl);
    await tester.pumpAndSettle();

    await tester.enterText(usernameField, testUsername);
    await tester.pumpAndSettle();

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    await tester.tap(loginBtn);
    await tester.pumpAndSettle();

    verifyNever(
        (getIt<PaperlessAuthenticationApi>() as MockPaperlessAuthenticationApi)
            .login(
      username: testUsername,
      password: testPassword,
    ));
    expect(
      find.textContaining(t.translations.loginPagePasswordValidatorMessageText),
      findsOneWidget,
    );
  });

  testWidgets('Test login validation missing username',
      (WidgetTester tester) async {
    await initAndLaunchTestApp(tester, () async {
      when((getIt<ConnectivityStatusService>() as MockConnectivityStatusService)
              .connectivityChanges())
          .thenAnswer((i) => Stream.value(true));
      when((getIt<LocalVault>() as MockLocalVault)
              .loadAuthenticationInformation())
          .thenAnswer((realInvocation) async => null);
      when((getIt<LocalVault>() as MockLocalVault).loadApplicationSettings())
          .thenAnswer((realInvocation) async => ApplicationSettingsState(
                preferredLocaleSubtag: 'en',
                preferredThemeMode: ThemeMode.light,
                isLocalAuthenticationEnabled: false,
                preferredViewType: ViewType.list,
                showInboxOnStartup: false,
              ));
      await getIt<ConnectivityCubit>().initialize();
      await getIt<ApplicationSettingsCubit>().initialize();
      await getIt<AuthenticationCubit>().initialize();
    });

    await t.binding.waitUntilFirstFrameRasterized;
    await tester.pumpAndSettle();

    await tester.enterText(serverAddressField, testServerUrl);
    await tester.pumpAndSettle();

    await tester.enterText(passwordField, testPassword);
    await tester.pumpAndSettle();

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    await tester.tap(loginBtn);
    await tester.pumpAndSettle();

    verifyNever(
        (getIt<PaperlessAuthenticationApi>() as MockPaperlessAuthenticationApi)
            .login(
      username: testUsername,
      password: testPassword,
    ));
    expect(
      find.textContaining(t.translations.loginPageUsernameValidatorMessageText),
      findsOneWidget,
    );
  });

  testWidgets('Test login validation missing server address',
      (WidgetTester tester) async {
    initAndLaunchTestApp(tester, () async {
      when((getIt<ConnectivityStatusService>()).connectivityChanges())
          .thenAnswer((i) => Stream.value(true));

      when((getIt<LocalVault>()).loadAuthenticationInformation())
          .thenAnswer((realInvocation) async => null);

      when((getIt<LocalVault>()).loadApplicationSettings())
          .thenAnswer((realInvocation) async => ApplicationSettingsState(
                preferredLocaleSubtag: 'en',
                preferredThemeMode: ThemeMode.light,
                isLocalAuthenticationEnabled: false,
                preferredViewType: ViewType.list,
                showInboxOnStartup: false,
              ));

      await getIt<ConnectivityCubit>().initialize();
      await getIt<ApplicationSettingsCubit>().initialize();
      await getIt<AuthenticationCubit>().initialize();
    });

    await t.binding.waitUntilFirstFrameRasterized;
    await tester.pumpAndSettle();

    await tester.enterText(usernameField, testUsername);
    await tester.pumpAndSettle();

    await tester.enterText(passwordField, testPassword);
    await tester.pumpAndSettle();

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    await tester.tap(loginBtn);
    await tester.pumpAndSettle();

    verifyNever(getIt<PaperlessAuthenticationApi>().login(
      username: testUsername,
      password: testPassword,
    ));
    expect(
      find.textContaining(
          t.translations.loginPageServerUrlValidatorMessageText),
      findsOneWidget,
    );
  });
}
