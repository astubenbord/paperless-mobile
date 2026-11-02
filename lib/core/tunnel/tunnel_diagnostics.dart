import 'dart:io';

import 'dns_client.dart';
import 'home_network_detector.dart';
import 'http_prober.dart';
import 'ipv4_cidr.dart';
import 'tunnel_channel.dart';

enum DiagnosticStatus { ok, warn, error, skipped }

enum DiagnosticsVerdict {
  tunnelDown,
  dnsOutsideTunnel,
  portUnreachable,
  notPaperless,
  tlsError,
  connectionOk,
  unknown,
}

class DiagnosticStep {
  const DiagnosticStep(
    this.id,
    this.status,
    this.title,
    this.data, {
    this.hint,
  });
  final String id;
  final DiagnosticStatus status;
  final String title;
  final Map<String, Object?> data;
  final String? hint;
}

class DiagnosticsReport {
  const DiagnosticsReport(
    this.date,
    this.serverHost,
    this.steps,
    this.verdict,
    this.verdictKey,
    this.parameters,
  );
  final DateTime date;
  final String serverHost;
  final List<DiagnosticStep> steps;
  final DiagnosticsVerdict verdict;
  final String verdictKey;
  final Map<String, Object?> parameters;
  // Never serialize untrusted titles, hints, parameters, host names or raw
  // platform data. They can contain credentials or an entire configuration.
  String toText() {
    String title(String id) => switch (id) {
      'home_network' => 'Heimnetz',
      'tunnel' => 'Tunnel',
      'config' => 'Einstellungen',
      'systemDns' => 'Namenssuche des Geräts',
      'vpnDns' => 'Namenssuche über VPN',
      'tcp' => 'Verbindung zum Server',
      'http' => 'Antwort von Paperless',
      'verdict' => 'Ergebnis',
      _ => 'Prüfung',
    };
    String status(DiagnosticStatus value) => switch (value) {
      DiagnosticStatus.ok => 'In Ordnung',
      DiagnosticStatus.warn => 'Hinweis',
      DiagnosticStatus.error => 'Fehler',
      DiagnosticStatus.skipped => 'Übersprungen',
    };
    final result = switch (verdict) {
      DiagnosticsVerdict.tunnelDown => 'Der Tunnel ist nicht verbunden.',
      DiagnosticsVerdict.dnsOutsideTunnel =>
        'Der Servername wird außerhalb des VPN gesucht.',
      DiagnosticsVerdict.portUnreachable => 'Der Server ist nicht erreichbar.',
      DiagnosticsVerdict.notPaperless =>
        'Der Server antwortet nicht als Paperless.',
      DiagnosticsVerdict.tlsError =>
        'Die sichere Verbindung ist fehlgeschlagen.',
      DiagnosticsVerdict.connectionOk =>
        'Die Verbindung zu Paperless funktioniert.',
      DiagnosticsVerdict.unknown =>
        'Die Verbindung konnte nicht geprüft werden.',
    };
    return [
      'Datum: ${date.toIso8601String()}',
      ...steps.map((step) => '${title(step.id)}: ${status(step.status)}'),
      'Ergebnis: $result',
      if (parameters['homeNetworkHint'] ==
          'Der Tunnel hilft hier nicht. Server oder Proxy prüfen.')
        'Der Tunnel hilft hier nicht. Server oder Proxy prüfen.',
      if (parameters['homeNetworkHint'] == 'Kein Tunnel konfiguriert.')
        'Kein Tunnel konfiguriert.',
      if (parameters['homeNetworkHint'] ==
          'Standortberechtigung und Standortdienst prüfen.')
        'Standortberechtigung und Standortdienst prüfen.',
    ].join('\n');
  }
}

typedef SystemResolver = Future<List<String>> Function(String host);
typedef TcpConnector = Future<Duration> Function(String address, int port);

class TunnelDiagnostics {
  TunnelDiagnostics(
    this.channel, {
    DnsClient? dnsClient,
    SystemResolver? resolver,
    TcpConnector? tcpConnector,
    HttpProber? httpProber,
    DateTime Function()? clock,
    HomeNetworkDetector? homeNetworkDetector,
    List<String> Function()? homeSsids,
  }) : dnsClient = dnsClient ?? DnsClient(),
       resolver = resolver ?? _resolve,
       tcpConnector = tcpConnector ?? _connect,
       httpProber = httpProber ?? HttpProber(),
       clock = clock ?? DateTime.now,
       homeNetworkDetector =
           homeNetworkDetector ?? HomeNetworkDetector(channel.currentSsid),
       homeSsids = homeSsids ?? _emptySsids;
  final HomeNetworkDetector homeNetworkDetector;
  final List<String> Function() homeSsids;
  static List<String> _emptySsids() => [];
  final TunnelChannel channel;
  final DnsClient dnsClient;
  final SystemResolver resolver;
  final TcpConnector tcpConnector;
  final HttpProber httpProber;
  final DateTime Function() clock;
  static Future<List<String>> _resolve(String host) async =>
      (await InternetAddress.lookup(
        host,
        type: InternetAddressType.IPv4,
      )).map((e) => e.address).toList();
  static Future<Duration> _connect(String address, int port) async {
    final watch = Stopwatch()..start();
    final socket = await Socket.connect(
      address,
      port,
      timeout: const Duration(seconds: 3),
    );
    socket.destroy();
    return watch.elapsed;
  }

  Future<DiagnosticsReport> run(
    String serverUrl, {
    void Function(DiagnosticStep step)? onStep,
  }) async {
    final uri = Uri.parse(serverUrl);
    final now = clock();
    final steps = <DiagnosticStep>[];
    void add(DiagnosticStep step) {
      steps.add(step);
      onStep?.call(step);
    }

    final configuredSsids = homeSsids();
    final home = await homeNetworkDetector.detect(configuredSsids);
    add(
      DiagnosticStep(
        'home_network',
        home.state == HomeNetworkState.unknown
            ? DiagnosticStatus.warn
            : DiagnosticStatus.ok,
        'Heimnetz',
        {
          'state': home.state.name,
          'ssid': home.ssid,
          'homeSsids': configuredSsids,
          'reason': home.reason?.name,
        },
      ),
    );
    TunnelDiagnosticsData? config;
    try {
      config = await channel.diagnostics();
    } catch (_) {
      add(
        DiagnosticStep('tunnel', DiagnosticStatus.error, 'Tunnel', {
          'error': 'Prüfung fehlgeschlagen',
        }),
      );
    }
    final peers = config?.peers ?? [];
    final handshake = peers.any((p) => p.lastHandshake != null);
    if (config != null) {
      add(
        DiagnosticStep(
          'tunnel',
          handshake && config.state == TunnelStatus.up
              ? DiagnosticStatus.ok
              : DiagnosticStatus.error,
          'Tunnel',
          {
            'state': config.state.name,
            'peers': peers
                .map(
                  (p) => {
                    'handshakeSeconds': p.lastHandshake == null
                        ? null
                        : now.difference(p.lastHandshake!).inSeconds,
                    'rxBytes': p.rxBytes,
                    'txBytes': p.txBytes,
                  },
                )
                .toList(),
          },
        ),
      );
      add(
        DiagnosticStep(
          'config',
          config.dnsServers.isEmpty
              ? DiagnosticStatus.warn
              : DiagnosticStatus.ok,
          'Konfiguration',
          {
            'addresses': config.interfaceAddresses,
            'dnsServers': config.dnsServers,
            'searchDomains': config.searchDomains,
            'mtu': config.mtu,
            'peers': peers
                .map(
                  (p) => {
                    'endpointHost': p.endpointHost,
                    'endpointPort': p.endpointPort,
                    'allowedIps': p.allowedIps,
                    'persistentKeepalive': p.persistentKeepalive,
                  },
                )
                .toList(),
          },
        ),
      );
    }
    final allowed = peers.expand((p) => p.allowedIps).toList();
    List<String> system = [];
    try {
      system = await resolver(uri.host);
      add(
        DiagnosticStep(
          'systemDns',
          system.isEmpty ? DiagnosticStatus.error : DiagnosticStatus.ok,
          'System DNS',
          {
            'addresses': system
                .map(
                  (ip) => {
                    'ip': ip,
                    'private': isPrivateIpv4(ip),
                    'allowed': allowed.any((cidr) => ipv4InCidr(ip, cidr)),
                  },
                )
                .toList(),
          },
        ),
      );
    } catch (_) {
      add(
        DiagnosticStep('systemDns', DiagnosticStatus.error, 'System DNS', {
          'error': 'Prüfung fehlgeschlagen',
        }),
      );
    }
    final vpn = <String>[];
    for (final server in config?.dnsServers ?? <String>[]) {
      try {
        final result = await dnsClient.lookup(uri.host, server);
        vpn.addAll(result.addresses);
        final differs =
            result.status == DnsStatus.success &&
            (system.toSet().difference(result.addresses.toSet()).isNotEmpty ||
                result.addresses.toSet().difference(system.toSet()).isNotEmpty);
        add(
          DiagnosticStep(
            'vpnDns',
            differs
                ? DiagnosticStatus.warn
                : result.status == DnsStatus.success
                ? DiagnosticStatus.ok
                : DiagnosticStatus.error,
            'VPN DNS',
            {
              'server': server,
              'status': result.status.name,
              'addresses': result.addresses,
            },
            hint: differs
                ? 'Das System fragt nicht den DNS-Server der VPN-Konfiguration'
                : null,
          ),
        );
      } catch (_) {
        add(
          DiagnosticStep('vpnDns', DiagnosticStatus.error, 'VPN DNS', {
            'server': server,
            'error': 'Prüfung fehlgeschlagen',
          }),
        );
      }
    }
    var connected = false;
    for (final ip in {...system, ...vpn}) {
      try {
        final elapsed = await tcpConnector(ip, uri.port);
        connected = true;
        add(
          DiagnosticStep('tcp', DiagnosticStatus.ok, 'TCP', {
            'ip': ip,
            'port': uri.port,
            'milliseconds': elapsed.inMilliseconds,
          }),
        );
      } catch (_) {
        add(
          DiagnosticStep('tcp', DiagnosticStatus.error, 'TCP', {
            'ip': ip,
            'port': uri.port,
            'error': 'Prüfung fehlgeschlagen',
          }),
        );
      }
    }
    final http = await httpProber.probe(serverUrl);
    add(
      DiagnosticStep(
        'http',
        http.isPaperless ? DiagnosticStatus.ok : DiagnosticStatus.error,
        'Paperless HTTP',
        {
          'status': http.statusCode,
          'error': http.error == null ? null : 'Prüfung fehlgeschlagen',
        },
        hint: http.statusCode != null && !http.isPaperless
            ? 'Antwort stammt nicht von Paperless, möglicherweise vom Reverse Proxy'
            : null,
      ),
    );
    final tls = http.error is TlsException || http.error is HandshakeException;
    final verdict = !handshake || config?.state != TunnelStatus.up
        ? DiagnosticsVerdict.tunnelDown
        : system.any((ip) => !isPrivateIpv4(ip)) && vpn.any(isPrivateIpv4)
        ? DiagnosticsVerdict.dnsOutsideTunnel
        : tls
        ? DiagnosticsVerdict.tlsError
        : !connected
        ? DiagnosticsVerdict.portUnreachable
        : !http.isPaperless
        ? DiagnosticsVerdict.notPaperless
        : DiagnosticsVerdict.connectionOk;
    final params = <String, Object?>{};
    if (home.state == HomeNetworkState.atHome && !http.isPaperless) {
      params['homeNetworkHint'] =
          'Der Tunnel hilft hier nicht. Server oder Proxy prüfen.';
    } else if (home.state == HomeNetworkState.away &&
        !await channel.hasConfig()) {
      params['homeNetworkHint'] = 'Kein Tunnel konfiguriert.';
    } else if (home.reason == HomeNetworkReason.permissionMissing ||
        home.reason == HomeNetworkReason.locationOff) {
      params['homeNetworkHint'] =
          'Standortberechtigung und Standortdienst prüfen.';
    }

    if (verdict == DiagnosticsVerdict.dnsOutsideTunnel)
      params['recommendation'] =
          'Server-Adresse fest zuordnen oder Auflösung über VPN-DNS einschalten';
    add(
      DiagnosticStep(
        'verdict',
        verdict == DiagnosticsVerdict.connectionOk
            ? DiagnosticStatus.ok
            : DiagnosticStatus.error,
        'Urteil',
        {'key': verdict.name, ...params},
      ),
    );
    return DiagnosticsReport(
      now,
      uri.host,
      steps,
      verdict,
      verdict.name,
      params,
    );
  }
}
