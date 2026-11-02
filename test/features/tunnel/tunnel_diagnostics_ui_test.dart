import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart' as log;
import 'package:paperless_mobile/core/tunnel/tunnel_diagnostics.dart';
import 'package:paperless_mobile/core/tunnel/tunnel_channel.dart';
import 'package:paperless_mobile/core/tunnel/tunnel_manager.dart';
import 'package:paperless_mobile/features/logging/data/logger.dart';
import 'package:paperless_mobile/features/logging/data/formatted_printer.dart';
import 'package:paperless_mobile/features/tunnel/view/tunnel_page.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/tunnel/tunnel_manager_test.dart' show FakeChannel;

const secret = 'PrivateKey = FAKE_SECRET_KEY_123456789';

class UnsafeDataChannel extends FakeChannel {
  @override
  Future<TunnelDiagnosticsData> diagnostics() async =>
      const TunnelDiagnosticsData(
        state: TunnelStatus.down,
        interfaceAddresses: [secret, '10.0.0.2/24'],
        dnsServers: [secret, '10.0.0.1'],
        searchDomains: [secret],
        peers: [
          TunnelPeerInfo(
            endpointHost: secret,
            allowedIps: [secret, '10.0.0.0/8'],
            rxBytes: 0,
            txBytes: 0,
          ),
        ],
      );
}

class FakeDiagnostics extends TunnelDiagnostics {
  FakeDiagnostics(super.channel);
  final complete = Completer<void>();
  int runs = 0;

  @override
  Future<DiagnosticsReport> run(
    String serverUrl, {
    void Function(DiagnosticStep step)? onStep,
  }) async {
    runs++;
    const first = DiagnosticStep('tunnel', DiagnosticStatus.ok, secret, {
      'privateKey': secret,
      'config': secret,
    }, hint: secret);
    const second = DiagnosticStep('http', DiagnosticStatus.error, secret, {
      'error': secret,
    });
    onStep?.call(first);
    await complete.future;
    onStep?.call(second);
    return DiagnosticsReport(
      DateTime.utc(2026),
      secret,
      [first, second],
      DiagnosticsVerdict.notPaperless,
      secret,
      const {'config': secret},
    );
  }
}

class CapturingOutput extends log.LogOutput {
  final lines = <String>[];
  @override
  void output(log.OutputEvent event) => lines.addAll(event.lines);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('report ignores untrusted diagnostic data', () {
    final report = DiagnosticsReport(
      DateTime.utc(2026),
      secret,
      const [
        DiagnosticStep('tunnel', DiagnosticStatus.ok, secret, {
          'privateKey': secret,
        }, hint: secret),
      ],
      DiagnosticsVerdict.connectionOk,
      secret,
      const {'config': secret},
    );
    expect(report.toText(), isNot(contains(secret)));
    expect(report.toText(), contains('Tunnel: In Ordnung'));
  });

  testWidgets('streams steps and copies a safe report', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final channel = UnsafeDataChannel();
    final diagnostics = FakeDiagnostics(channel);
    final manager = TunnelManager(
      channel,
      await SharedPreferences.getInstance(),
    );
    final output = CapturingOutput();
    logger = log.Logger(printer: FormattedPrinter(), output: output);
    String? clipboard;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData')
          clipboard = (call.arguments as Map)['text'] as String?;
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
      manager.dispose();
    });
    await tester.pumpWidget(
      Provider.value(
        value: manager,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: TunnelPage(
            initialServerUrl: 'https://example.test',
            diagnostics: diagnostics,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining(secret), findsNothing);
    expect(find.textContaining('10.0.0.2/24'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Check connection in detail'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Check connection in detail'));
    await tester.pump();
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    diagnostics.complete.complete();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(
        'The server did not answer as Paperless. Check the server address.',
      ),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Paperless response'), findsOneWidget);
    expect(
      find.text(
        'The server did not answer as Paperless. Check the server address.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining(secret), findsNothing);
    await tester.tap(find.text('Paperless response'));
    await tester.pumpAndSettle();
    expect(find.textContaining(secret), findsNothing);
    await tester.tap(find.text('Cancel').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Copy report'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Copy report'));
    await tester.pump();
    expect(clipboard, contains('Tunnel: In Ordnung'));
    expect(clipboard, isNot(contains(secret)));
    expect(find.text('Report copied'), findsOneWidget);
    expect(output.lines.join('\n'), contains('Tunnel: In Ordnung'));
    expect(output.lines.join('\n'), isNot(contains(secret)));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('failed connection test offers details and starts diagnostics', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final channel = FakeChannel();
    final diagnostics = FakeDiagnostics(channel);
    final manager = TunnelManager(
      channel,
      await SharedPreferences.getInstance(),
      probe: (_) async => false,
      connectTimeout: Duration.zero,
      pollInterval: Duration.zero,
    );
    logger = log.Logger(printer: FormattedPrinter(), output: CapturingOutput());
    addTearDown(manager.dispose);
    await tester.pumpWidget(
      Provider.value(
        value: manager,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: TunnelPage(
            initialServerUrl: 'https://example.test',
            diagnostics: diagnostics,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Test connection'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Test connection'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Show details'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Show details'), findsOneWidget);
    expect(
      find.textContaining('Settings → Connection on the go'),
      findsOneWidget,
    );
    await tester.tap(find.text('Show details'));
    await tester.pump();
    expect(diagnostics.runs, 1);
    diagnostics.complete.complete();
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
