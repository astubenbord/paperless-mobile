import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_mobile/core/tunnel/location_permission.dart';
import 'package:paperless_mobile/core/tunnel/tunnel_channel.dart';
import 'package:paperless_mobile/core/tunnel/tunnel_manager.dart';
import 'package:paperless_mobile/features/tunnel/view/tunnel_page.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/tunnel/tunnel_manager_test.dart' show FakeChannel;

class FakeLocation implements LocationPermission {
  PermissionStatus value = PermissionStatus.granted;
  int settingsCalls = 0;
  @override
  Future<PermissionStatus> status() async => value;
  @override
  Future<PermissionStatus> request() async => value;
  @override
  Future<bool> openSettings() async {
    settingsCalls++;
    return true;
  }

  @override
  bool isPermanentlyDenied(PermissionStatus status) =>
      status == PermissionStatus.permanentlyDenied;
}

void main() {
  testWidgets('home Wi-Fi editing and current network outcomes', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final channel = FakeChannel();
    final permission = FakeLocation();
    final manager = TunnelManager(
      channel,
      await SharedPreferences.getInstance(),
    );
    await tester.pumpWidget(
      Provider.value(
        value: manager,
        child: MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: TunnelPage(locationPermission: permission),
        ),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> reveal(Finder finder) async {
      await tester.scrollUntilVisible(
        finder,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
    }

    await reveal(find.text('Home network (Wi-Fi)'));
    expect(find.text('Home network (Wi-Fi)'), findsOneWidget);
    expect(find.textContaining('cannot detect'), findsOneWidget);
    await reveal(find.text('Wi-Fi name'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Wi-Fi name'),
      'Home',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();
    expect(manager.homeSsids, ['Home']);
    await tester.enterText(
      find.widgetWithText(TextField, 'Wi-Fi name'),
      'Home',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();
    expect(find.text('Invalid or duplicate Wi-Fi name.'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Wi-Fi name'), ' ');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();
    expect(find.text('Invalid or duplicate Wi-Fi name.'), findsOneWidget);
    await reveal(find.byTooltip('Delete Wi-Fi name'));
    await tester.tap(find.byTooltip('Delete Wi-Fi name'));
    await tester.pumpAndSettle();
    expect(manager.homeSsids, isEmpty);
    await reveal(find.text('Use current Wi-Fi'));
    channel.ssid = const SsidResult('Home', SsidStatus.ok);
    await tester.tap(find.text('Use current Wi-Fi'));
    await tester.pumpAndSettle();
    expect(manager.homeSsids, ['Home']);
    expect(find.textContaining("at home (Wi-Fi 'Home')"), findsOneWidget);
    permission.value = PermissionStatus.denied;
    await tester.tap(find.text('Use current Wi-Fi'));
    await tester.pumpAndSettle();
    expect(find.text('Location permission missing'), findsOneWidget);
    permission.value = PermissionStatus.permanentlyDenied;
    await tester.tap(find.text('Use current Wi-Fi'));
    await tester.pumpAndSettle();
    expect(find.text('Open app settings'), findsOneWidget);
    await tester.tap(find.text('Open app settings'));
    expect(permission.settingsCalls, 1);
    permission.value = PermissionStatus.granted;
    for (final entry in [
      (SsidStatus.locationOff, 'Turn on location services'),
      (SsidStatus.notWifi, 'You are not connected to Wi-Fi'),
    ]) {
      channel.ssid = SsidResult(null, entry.$1);
      await tester.tap(find.text('Use current Wi-Fi'));
      await tester.pumpAndSettle();
      expect(find.text(entry.$2), findsOneWidget);
    }
    await tester.pumpWidget(const SizedBox.shrink());
    manager.dispose();
  });
}
