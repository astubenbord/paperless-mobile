import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_mobile/core/tunnel/tunnel_channel.dart';
import 'package:paperless_mobile/core/tunnel/tunnel_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeChannel implements TunnelChannel {
  bool permitted = true;
  bool configured = true;
  TunnelStatus current = TunnelStatus.down;
  int ups = 0;
  int downs = 0;
  @override
  Future<bool> hasConfig() async => configured;
  @override
  Future<bool> isPermitted() async => permitted;
  @override
  Future<bool> requestPermission() async => permitted;
  @override
  Future<TunnelStatus> status() async => current;
  @override
  Future<TunnelStatus> up() async {
    ups++;
    return current = TunnelStatus.up;
  }

  @override
  Future<TunnelStatus> down() async {
    downs++;
    return current = TunnelStatus.down;
  }

  @override
  Future<void> deleteConfig() async {
    configured = false;
  }

  @override
  Future<TunnelConfigInfo> importConfig(String text) async =>
      const TunnelConfigInfo(
        endpointHost: 'host',
        peerCount: 1,
        interfaceAddresses: [],
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeChannel channel;
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({'tunnel.enabled': true});
    prefs = await SharedPreferences.getInstance();
    channel = FakeChannel();
  });
  test('directly reachable does not start tunnel', () async {
    final manager = TunnelManager(channel, prefs, probe: (_) async => true);
    await manager.ensureReachable('https://example.test');
    expect(channel.ups, 0);
    manager.dispose();
  });
  test('unreachable server starts tunnel and retries', () async {
    var probes = 0;
    final manager = TunnelManager(
      channel,
      prefs,
      probe: (_) async => ++probes > 1,
    );
    await manager.ensureReachable('https://example.test');
    expect(channel.ups, 1);
    expect(manager.state.value.state, TunnelConnectionState.connected);
    manager.dispose();
  });
  test('missing permission reports error', () async {
    channel.permitted = false;
    final manager = TunnelManager(channel, prefs, probe: (_) async => false);
    await expectLater(
      manager.ensureReachable('https://example.test'),
      throwsA(
        isA<TunnelException>().having(
          (e) => e.code,
          'code',
          'vpn_not_authorized',
        ),
      ),
    );
    expect(channel.ups, 0);
    manager.dispose();
  });
  test('paused disconnects after delay', () async {
    var probes = 0;
    final manager = TunnelManager(
      channel,
      prefs,
      probe: (_) async => ++probes > 1,
      delayUnit: const Duration(milliseconds: 5),
    );
    await manager.setDelayMinutes(1);
    await manager.ensureReachable('https://example.test');
    manager.didChangeAppLifecycleState(AppLifecycleState.paused);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(channel.downs, 1);
    manager.dispose();
  });
  test('concurrent requests share a start', () async {
    final gate = Completer<bool>();
    var calls = 0;
    final manager = TunnelManager(
      channel,
      prefs,
      probe: (_) {
        calls++;
        return calls == 1 ? gate.future : Future.value(true);
      },
    );
    final first = manager.ensureReachable('https://example.test');
    final second = manager.ensureReachable('https://example.test');
    gate.complete(false);
    await Future.wait([first, second]);
    expect(channel.ups, 1);
    manager.dispose();
  });
}
