import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_mobile/core/tunnel/tunnel_manager.dart';
import 'package:paperless_mobile/features/tunnel/view/tunnel_page.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/tunnel/tunnel_manager_test.dart' show FakeChannel;

void main() {
  testWidgets('shows setup steps and saved configuration', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final manager = TunnelManager(
      FakeChannel(),
      await SharedPreferences.getInstance(),
    );
    await tester.pumpWidget(
      Provider.value(
        value: manager,
        child: const MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: TunnelPage(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('1. Add your WireGuard file'), findsOneWidget);
    expect(find.text('A configuration is saved.'), findsOneWidget);
    expect(find.text('2. Allow VPN'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    manager.dispose();
  });
}
