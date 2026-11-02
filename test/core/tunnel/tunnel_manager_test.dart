import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_mobile/core/tunnel/tunnel_channel.dart';
import 'package:paperless_mobile/core/tunnel/tunnel_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeChannel implements TunnelChannel {
  @override
  Future<SsidResult> currentSsid() async {
    ssidCalls++;
    return ssid;
  }

  int ssidCalls = 0;
  SsidResult ssid = const SsidResult(null, SsidStatus.unknown);

  @override
  Future<TunnelDiagnosticsData> diagnostics() async =>
      const TunnelDiagnosticsData(
        state: TunnelStatus.down,
        interfaceAddresses: [],
        dnsServers: [],
        searchDomains: [],
        peers: [],
      );
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
    final manager = TunnelManager(
      channel,
      prefs,
      connectivityChanges: const Stream.empty(),
      probe: (_) async => true,
    );
    await manager.ensureReachable('https://example.test');
    expect(channel.ups, 0);
    manager.dispose();
  });
  test('unreachable server starts tunnel and retries', () async {
    var probes = 0;
    final manager = TunnelManager(
      channel,
      prefs,
      connectivityChanges: const Stream.empty(),
      probe: (_) async => ++probes > 1,
    );
    await manager.ensureReachable('https://example.test');
    expect(channel.ups, 1);
    expect(manager.state.value.state, TunnelConnectionState.connected);
    manager.dispose();
  });
  test('missing permission reports error', () async {
    channel.permitted = false;
    final manager = TunnelManager(
      channel,
      prefs,
      connectivityChanges: const Stream.empty(),
      probe: (_) async => false,
    );
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
      connectivityChanges: const Stream.empty(),
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
      connectivityChanges: const Stream.empty(),
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
  test('home SSIDs are normalized, validated and removed exactly', () async {
    final manager = TunnelManager(
      channel,
      prefs,
      connectivityChanges: const Stream.empty(),
    );
    for (final value in [
      ' ',
      '""',
      '<unknown ssid>',
      ' "<UNKNOWN SSID>" ',
      '0x',
      ' " Home " ',
      'Home',
      'home',
    ]) {
      await manager.addHomeSsid(value);
    }
    expect(manager.homeSsids, ['Home', 'home']);
    await manager.removeHomeSsid('Home');
    expect(manager.homeSsids, ['home']);
    expect(manager.createDiagnostics().homeSsids(), ['home']);
    manager.dispose();
  });

  test('at home neither starts a tunnel nor probes', () async {
    channel.ssid = const SsidResult('Home', SsidStatus.ok);
    var probes = 0;
    final manager = TunnelManager(
      channel,
      prefs,
      connectivityChanges: const Stream.empty(),
      probe: (_) async {
        probes++;
        return true;
      },
    );
    await manager.addHomeSsid('Home');
    await manager.ensureReachable('https://example.test');
    expect(channel.ups, 0);
    expect(probes, 0);
    expect(manager.state.value.atHome, isTrue);
    manager.dispose();
  });

  test(
    'away starts before probing; unknown and empty list probe directly',
    () async {
      var probes = 0;
      final manager = TunnelManager(
        channel,
        prefs,
        connectivityChanges: const Stream.empty(),
        probe: (_) async {
          probes++;
          if (channel.ssid.status == SsidStatus.ok) expect(channel.ups, 1);
          return true;
        },
      );
      await manager.addHomeSsid('Home');
      channel.ssid = const SsidResult(null, SsidStatus.permissionMissing);
      await manager.ensureReachable('https://example.test');
      expect(probes, 1);
      expect(channel.ups, 0);
      await manager.setHomeSsids([]);
      await manager.ensureReachable('https://example.test');
      expect(probes, 2);
      expect(channel.ups, 0);
      await manager.addHomeSsid('Home');
      channel.ssid = const SsidResult('Other', SsidStatus.ok);
      await manager.ensureReachable('https://example.test');
      expect(channel.ups, 1);
      expect(probes, 3);
      manager.dispose();
    },
  );

  test(
    'network changes debounce and stop a tunnel started by this app at home',
    () async {
      final changes = StreamController<List<ConnectivityResult>>();
      channel.ssid = const SsidResult('Other', SsidStatus.ok);
      final manager = TunnelManager(
        channel,
        prefs,
        connectivityChanges: changes.stream,
        probe: (_) async => true,
      );
      await manager.addHomeSsid('Home');
      await manager.ensureReachable('https://example.test');
      expect(channel.ups, 1);
      channel.ssid = const SsidResult('Home', SsidStatus.ok);
      changes.add([ConnectivityResult.wifi]);
      changes.add([ConnectivityResult.wifi]);
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      expect(channel.downs, 1);
      expect(channel.ssidCalls, 2);
      expect(manager.state.value.atHome, isTrue);
      manager.dispose();
      await changes.close();
    },
  );

  test('at home leaves a tunnel started outside the app running', () async {
    channel.current = TunnelStatus.up;
    channel.ssid = const SsidResult('Home', SsidStatus.ok);
    final manager = TunnelManager(
      channel,
      prefs,
      connectivityChanges: const Stream.empty(),
    );
    await manager.addHomeSsid('Home');
    await manager.ensureReachable('https://example.test');
    expect(channel.downs, 0);
    expect(channel.current, TunnelStatus.up);
    manager.dispose();
  });
}
