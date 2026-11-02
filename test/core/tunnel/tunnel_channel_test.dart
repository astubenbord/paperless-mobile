import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_mobile/core/tunnel/tunnel_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('de.astubenbord.paperless_mobile/tunnel');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final tunnel = MethodTunnelChannel(channel: channel);

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('imports metadata and forwards configuration', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'importConfig');
      expect(call.arguments, {'text': 'example'});
      return {
        'endpointHost': 'vpn.example.com',
        'peerCount': 1,
        'interfaceAddresses': ['192.0.2.2/32'],
      };
    });
    final info = await tunnel.importConfig('example');
    expect(info.endpointHost, 'vpn.example.com');
    expect(info.peerCount, 1);
    expect(info.interfaceAddresses, ['192.0.2.2/32']);
  });

  test('maps status and platform errors', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'up') return 'UP';
      if (call.method == 'status') return 'DOWN';
      throw PlatformException(
        code: 'vpn_not_authorized',
        message: 'not exposed',
      );
    });
    expect(await tunnel.up(), TunnelStatus.up);
    expect(await tunnel.status(), TunnelStatus.down);
    expect(
      () => tunnel.down(),
      throwsA(
        isA<TunnelException>().having(
          (e) => e.code,
          'code',
          'vpn_not_authorized',
        ),
      ),
    );
  });
  test('parses diagnostics and defaults missing fields', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (call) async => {
        'state': 'UP',
        'dnsServers': ['192.0.2.53'],
        'peers': [
          {
            'endpointHost': 'vpn.example.com',
            'endpointPort': 51820,
            'allowedIps': ['192.0.2.0/24'],
            'lastHandshakeEpochMillis': 1000,
          },
          {},
        ],
      },
    );
    final data = await tunnel.diagnostics();
    expect(data.state, TunnelStatus.up);
    expect(data.dnsServers, ['192.0.2.53']);
    expect(data.interfaceAddresses, isEmpty);
    expect(data.mtu, isNull);
    expect(data.peers.first.endpointPort, 51820);
    expect(data.peers.first.allowedIps, ['192.0.2.0/24']);
    expect(
      data.peers.first.lastHandshake,
      DateTime.fromMillisecondsSinceEpoch(1000, isUtc: true),
    );
    expect(data.peers.last.lastHandshake, isNull);
    expect(data.peers.last.rxBytes, 0);
  });
}
