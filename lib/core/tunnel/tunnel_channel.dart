import 'package:flutter/services.dart';

class TunnelConfigInfo {
  const TunnelConfigInfo({
    required this.endpointHost,
    required this.peerCount,
    required this.interfaceAddresses,
  });

  final String endpointHost;
  final int peerCount;
  final List<String> interfaceAddresses;
}

class TunnelPeerInfo {
  const TunnelPeerInfo({
    this.endpointHost,
    this.endpointPort,
    required this.allowedIps,
    this.persistentKeepalive,
    required this.rxBytes,
    required this.txBytes,
    this.lastHandshake,
  });
  final String? endpointHost;
  final int? endpointPort;
  final List<String> allowedIps;
  final int? persistentKeepalive;
  final int rxBytes;
  final int txBytes;
  final DateTime? lastHandshake;
}

class TunnelDiagnosticsData {
  const TunnelDiagnosticsData({
    required this.state,
    required this.interfaceAddresses,
    required this.dnsServers,
    required this.searchDomains,
    this.mtu,
    required this.peers,
  });
  final TunnelStatus state;
  final List<String> interfaceAddresses;
  final List<String> dnsServers;
  final List<String> searchDomains;
  final int? mtu;
  final List<TunnelPeerInfo> peers;
}

List<String> _strings(Object? value) =>
    value is List ? value.whereType<String>().toList() : [];

enum SsidStatus { ok, permissionMissing, locationOff, notWifi, unknown }

class SsidResult {
  const SsidResult(this.ssid, this.status);
  final String? ssid;
  final SsidStatus status;
}

enum TunnelStatus { up, down }

class TunnelException implements Exception {
  const TunnelException(this.code);
  final String code;
  @override
  String toString() => 'TunnelException($code)';
}

/// Interface can be implemented by consumers in tests.
abstract class TunnelChannel {
  factory TunnelChannel() = MethodTunnelChannel;
  Future<TunnelConfigInfo> importConfig(String text);
  Future<bool> hasConfig();
  Future<void> deleteConfig();
  Future<bool> isPermitted();
  Future<bool> requestPermission();
  Future<TunnelStatus> up();
  Future<TunnelStatus> down();
  Future<TunnelStatus> status();
  Future<TunnelDiagnosticsData> diagnostics();
  Future<SsidResult> currentSsid();
}

class MethodTunnelChannel implements TunnelChannel {
  MethodTunnelChannel({MethodChannel? channel})
    : _channel =
          channel ?? const MethodChannel('de.astubenbord.paperless_mobile/tunnel');
  final MethodChannel _channel;

  Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on PlatformException catch (e) {
      throw TunnelException(e.code);
    } on MissingPluginException {
      throw const TunnelException('library_missing');
    }
  }

  @override
  Future<TunnelConfigInfo> importConfig(String text) async {
    final info = (await _invoke<Map<Object?, Object?>>('importConfig', {
      'text': text,
    }))!;
    return TunnelConfigInfo(
      endpointHost: info['endpointHost']! as String,
      peerCount: info['peerCount']! as int,
      interfaceAddresses: (info['interfaceAddresses']! as List<Object?>)
          .cast<String>(),
    );
  }

  @override
  Future<TunnelDiagnosticsData> diagnostics() async {
    final data = await _invoke<Map<Object?, Object?>>('diagnostics') ?? {};
    final rawPeers = data['peers'];
    final peers = <TunnelPeerInfo>[];
    if (rawPeers is List) {
      for (final item in rawPeers) {
        if (item is! Map) continue;
        final timestamp = item['lastHandshakeEpochMillis'];
        peers.add(
          TunnelPeerInfo(
            endpointHost: item['endpointHost'] is String
                ? item['endpointHost'] as String
                : null,
            endpointPort: item['endpointPort'] is int
                ? item['endpointPort'] as int
                : null,
            allowedIps: _strings(item['allowedIps']),
            persistentKeepalive: item['persistentKeepalive'] is int
                ? item['persistentKeepalive'] as int
                : null,
            rxBytes: item['rxBytes'] is int ? item['rxBytes'] as int : 0,
            txBytes: item['txBytes'] is int ? item['txBytes'] as int : 0,
            lastHandshake: timestamp is int && timestamp > 0
                ? DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true)
                : null,
          ),
        );
      }
    }
    return TunnelDiagnosticsData(
      state: data['state'] == 'UP' ? TunnelStatus.up : TunnelStatus.down,
      interfaceAddresses: _strings(data['interfaceAddresses']),
      dnsServers: _strings(data['dnsServers']),
      searchDomains: _strings(data['searchDomains']),
      mtu: data['mtu'] is int ? data['mtu'] as int : null,
      peers: peers,
    );
  }

  @override
  Future<SsidResult> currentSsid() async {
    final data = await _invoke<Object>('currentSsid');
    if (data is! Map) return const SsidResult(null, SsidStatus.unknown);
    final status = switch (data['status']) {
      'ok' => SsidStatus.ok,
      'permission_missing' => SsidStatus.permissionMissing,
      'location_off' => SsidStatus.locationOff,
      'not_wifi' => SsidStatus.notWifi,
      _ => SsidStatus.unknown,
    };
    final ssid = data['ssid'];
    return SsidResult(ssid is String ? ssid : null, status);
  }

  @override
  Future<bool> hasConfig() async => (await _invoke<bool>('hasConfig'))!;
  @override
  Future<void> deleteConfig() async {
    await _invoke<void>('deleteConfig');
  }

  @override
  Future<bool> isPermitted() async => (await _invoke<bool>('isPermitted'))!;
  @override
  Future<bool> requestPermission() async =>
      (await _invoke<bool>('requestPermission'))!;

  Future<TunnelStatus> _status(String method) async {
    final value = await _invoke<String>(method);
    switch (value) {
      case 'UP':
        return TunnelStatus.up;
      case 'DOWN':
        return TunnelStatus.down;
      default:
        throw const TunnelException('unknown');
    }
  }

  @override
  Future<TunnelStatus> up() => _status('up');
  @override
  Future<TunnelStatus> down() => _status('down');
  @override
  Future<TunnelStatus> status() => _status('status');
}
