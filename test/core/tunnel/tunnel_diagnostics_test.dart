import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_mobile/core/tunnel/dns_client.dart';
import 'package:paperless_mobile/core/tunnel/http_prober.dart';
import 'package:paperless_mobile/core/tunnel/tunnel_channel.dart';
import 'package:paperless_mobile/core/tunnel/tunnel_diagnostics.dart';
import 'tunnel_manager_test.dart' show FakeChannel;

class DiagnosticChannel extends FakeChannel {
  DiagnosticChannel(this.handshake);
  final bool handshake;
  @override
  Future<TunnelDiagnosticsData> diagnostics() async => TunnelDiagnosticsData(
    state: TunnelStatus.up,
    interfaceAddresses: ['10.0.0.2/24'],
    dnsServers: ['10.0.0.1'],
    searchDomains: [],
    peers: [
      TunnelPeerInfo(
        allowedIps: ['10.0.0.0/8'],
        rxBytes: 1,
        txBytes: 2,
        lastHandshake: handshake ? DateTime.utc(2026) : null,
      ),
    ],
  );
}

void main() {
  Future<DiagnosticsVerdict> run({
    bool handshake = true,
    bool external = false,
    int status = 200,
    bool tls = false,
  }) async {
    final dns = DnsClient(
      exchange: (server, query) async {
        final response = <int>[...query];
        response[2] = 0x81;
        response[3] = 0x80;
        response[7] = 1;
        response.addAll([0xc0, 12, 0, 1, 0, 1, 0, 0, 0, 1, 0, 4, 10, 0, 0, 4]);
        return response;
      },
    );
    final diagnostics = TunnelDiagnostics(
      DiagnosticChannel(handshake),
      dnsClient: dns,
      resolver: (_) async => [external ? '8.8.8.8' : '10.0.0.4'],
      tcpConnector: (_, __) async => const Duration(milliseconds: 1),
      httpProber: HttpProber(
        request: (_) async => tls
            ? HttpProbeResult(error: HandshakeException('certificate'))
            : HttpProbeResult(
                statusCode: status,
                contentType: status == 200 ? 'application/json' : 'text/html',
                server: 'openresty',
              ),
      ),
    );
    return (await diagnostics.run('https://example.com')).verdict;
  }

  test('classifies diagnostic scenarios', () async {
    expect(await run(handshake: false), DiagnosticsVerdict.tunnelDown);
    expect(await run(external: true), DiagnosticsVerdict.dnsOutsideTunnel);
    expect(await run(status: 403), DiagnosticsVerdict.notPaperless);
    expect(await run(tls: true), DiagnosticsVerdict.tlsError);
    expect(await run(), DiagnosticsVerdict.connectionOk);
  });
  test(
    'home network step uses saved SSIDs and explains unknown status',
    () async {
      final channel = DiagnosticChannel(true)
        ..ssid = const SsidResult('Home', SsidStatus.ok);
      final names = <String>['Home'];
      final diagnostics = TunnelDiagnostics(
        channel,
        homeSsids: () => names,
        resolver: (_) async => [],
        dnsClient: DnsClient(exchange: (_, _) async => throw Exception()),
        httpProber: HttpProber(
          request: (_) async => HttpProbeResult(statusCode: 503),
        ),
      );
      var report = await diagnostics.run('https://example.com');
      var step = report.steps.singleWhere((step) => step.id == 'home_network');
      expect(step.data['state'], 'atHome');
      expect(step.data['ssid'], 'Home');
      expect(step.data['homeSsids'], ['Home']);
      expect(report.toText(), contains('Server oder Proxy prüfen'));
      channel.ssid = const SsidResult(null, SsidStatus.permissionMissing);
      report = await diagnostics.run('https://example.com');
      step = report.steps.singleWhere((step) => step.id == 'home_network');
      expect(step.data['reason'], 'permissionMissing');
      expect(report.toText(), contains('Standortberechtigung'));
      channel.ssid = const SsidResult('Other', SsidStatus.ok);
      channel.configured = false;
      report = await diagnostics.run('https://example.com');
      expect(report.toText(), contains('Kein Tunnel konfiguriert'));
    },
  );
}
