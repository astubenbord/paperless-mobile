import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'home_network_detector.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tunnel_channel.dart';
import 'tunnel_diagnostics.dart';
import 'http_prober.dart';

enum TunnelConnectionState { off, connecting, connected, error }

class TunnelViewState {
  const TunnelViewState(this.state, [this.errorCode, this.atHome = false]);
  final TunnelConnectionState state;
  final String? errorCode;
  final bool atHome;
}

typedef ServerProbe = Future<bool> Function(String url);

/// Coordinates automatic tunnel use. Configuration contents stay in native storage.
class TunnelManager with WidgetsBindingObserver {
  TunnelManager(
    this.channel,
    this.preferences, {
    ServerProbe? probe,
    HomeNetworkDetector? homeNetworkDetector,
    Stream<List<ConnectivityResult>>? connectivityChanges,
    this.pollInterval = const Duration(milliseconds: 500),
    this.connectTimeout = const Duration(seconds: 15),
    this.delayUnit = const Duration(minutes: 1),
  }) : probe = probe ?? probeServer,
       homeNetworkDetector =
           homeNetworkDetector ?? HomeNetworkDetector(channel.currentSsid) {
    _connectivitySubscription =
        (connectivityChanges ?? Connectivity().onConnectivityChanged).listen((
          _,
        ) {
          if (!_foreground) return;
          _networkTimer?.cancel();
          _networkTimer = Timer(const Duration(seconds: 1), () {
            final server = _server;
            if (server != null)
              unawaited(ensureReachable(server).catchError((Object _) {}));
          });
        });
  }

  final HomeNetworkDetector homeNetworkDetector;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _networkTimer;
  bool _foreground = true;
  final TunnelChannel channel;
  final SharedPreferences preferences;
  final ServerProbe probe;
  final Duration pollInterval;
  final Duration connectTimeout;
  final Duration delayUnit;
  final ValueNotifier<TunnelViewState> state = ValueNotifier(
    const TunnelViewState(TunnelConnectionState.off),
  );
  Future<void>? _pending;
  String? _pendingUrl;
  Timer? _timer;
  bool _started = false;
  String? _server;

  TunnelDiagnostics createDiagnostics() => TunnelDiagnostics(
    channel,
    homeNetworkDetector: homeNetworkDetector,
    homeSsids: () => homeSsids,
  );

  List<String> get homeSsids =>
      preferences.getStringList('tunnel.homeSsids') ?? [];
  Future<void> setHomeSsids(List<String> value) async =>
      preferences.setStringList('tunnel.homeSsids', value);
  Future<void> addHomeSsid(String ssid) async {
    var value = ssid.trim();
    if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) {
      value = value.substring(1, value.length - 1).trim();
    }
    if (value.isEmpty ||
        value.toLowerCase() == '<unknown ssid>' ||
        value == '0x')
      return;
    final list = homeSsids;
    if (!list.contains(value)) await setHomeSsids([...list, value]);
  }

  Future<void> removeHomeSsid(String ssid) async =>
      setHomeSsids(homeSsids.where((s) => s != ssid).toList());

  bool get enabled => preferences.getBool('tunnel.enabled') ?? false;
  bool get directCheck => preferences.getBool('tunnel.directCheck') ?? true;
  int get delayMinutes => preferences.getInt('tunnel.delayMinutes') ?? 5;
  Future<void> setEnabled(bool value) async {
    await preferences.setBool('tunnel.enabled', value);
  }

  Future<void> setDirectCheck(bool value) async {
    await preferences.setBool('tunnel.directCheck', value);
  }

  /// Zero means never disconnect automatically.
  Future<void> setDelayMinutes(int value) async {
    if (![0, 1, 5, 15, 30].contains(value)) throw ArgumentError.value(value);
    await preferences.setInt('tunnel.delayMinutes', value);
  }

  Future<void> ensureReachable(String serverUrl) {
    _server = serverUrl;
    final previous = _pending;
    if (previous != null) {
      return _pendingUrl == serverUrl
          ? previous
          : previous.then((_) => ensureReachable(serverUrl));
    }
    _pendingUrl = serverUrl;
    final future = _ensure(serverUrl).whenComplete(() {
      _pending = null;
      _pendingUrl = null;
    });
    _pending = future;
    return future;
  }

  Future<void> refreshStatus() async {
    final current = await channel.status();
    state.value = TunnelViewState(
      current == TunnelStatus.up
          ? TunnelConnectionState.connected
          : TunnelConnectionState.off,
    );
  }

  Future<void> deleteConfig() async {
    _timer?.cancel();
    if (await channel.status() == TunnelStatus.up) await channel.down();
    _started = false;
    await channel.deleteConfig();
    state.value = const TunnelViewState(TunnelConnectionState.off);
  }

  Future<void> testConnection(String url) async {
    if (!await channel.hasConfig())
      throw const TunnelException('config_missing');
    if (!await channel.isPermitted())
      throw const TunnelException('vpn_not_authorized');
    final wasUp = await channel.status() == TunnelStatus.up;
    try {
      if (!wasUp && await channel.up() != TunnelStatus.up) {
        throw const TunnelException('vpn_start_failed');
      }
      final deadline = DateTime.now().add(connectTimeout);
      do {
        if (await probe(url)) return;
        await Future<void>.delayed(pollInterval);
      } while (DateTime.now().isBefore(deadline));
      throw const TunnelException('server_unreachable');
    } finally {
      if (!wasUp) await channel.down();
    }
  }

  Future<void> _ensure(String url) async {
    try {
      if (!enabled) return;
      final home = await homeNetworkDetector.detect(homeSsids);
      if (home.state == HomeNetworkState.atHome) {
        if (_started) {
          if (await channel.status() == TunnelStatus.up) await channel.down();
          _started = false;
        }
        state.value = const TunnelViewState(
          TunnelConnectionState.off,
          null,
          true,
        );
        return;
      }
      if (!await channel.hasConfig()) return;
      if (home.state != HomeNetworkState.away &&
          directCheck &&
          await probe(url))
        return;
      state.value = const TunnelViewState(TunnelConnectionState.connecting);
      if (!await channel.isPermitted())
        throw const TunnelException('vpn_not_authorized');
      final wasUp = await channel.status() == TunnelStatus.up;
      if (!wasUp) {
        if (await channel.up() != TunnelStatus.up)
          throw const TunnelException('vpn_start_failed');
        _started = true;
      }
      final deadline = DateTime.now().add(connectTimeout);
      do {
        if (await probe(url)) {
          state.value = const TunnelViewState(TunnelConnectionState.connected);
          return;
        }
        await Future<void>.delayed(pollInterval);
      } while (DateTime.now().isBefore(deadline));
      throw const TunnelException('server_unreachable');
    } catch (error) {
      final exception = error is TunnelException
          ? error
          : const TunnelException('unknown');
      state.value = TunnelViewState(
        TunnelConnectionState.error,
        exception.code,
      );
      throw exception;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    _foreground = lifecycle == AppLifecycleState.resumed;
    if (!_foreground) _networkTimer?.cancel();
    if (lifecycle == AppLifecycleState.paused &&
        _started &&
        delayMinutes != 0) {
      _timer?.cancel();
      _timer = Timer(delayUnit * delayMinutes, () async {
        try {
          await channel.down();
          _started = false;
          state.value = const TunnelViewState(TunnelConnectionState.off);
        } on TunnelException catch (error) {
          state.value = TunnelViewState(
            TunnelConnectionState.error,
            error.code,
          );
        }
      });
    } else if (lifecycle == AppLifecycleState.resumed) {
      _timer?.cancel();
      final server = _server;
      if (server != null)
        unawaited(ensureReachable(server).catchError((Object _) {}));
    }
  }

  void dispose() {
    _timer?.cancel();
    _networkTimer?.cancel();
    _connectivitySubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    state.dispose();
  }

  static Future<bool> probeServer(String url) async =>
      (await HttpProber().probe(url)).isPaperless;
}
