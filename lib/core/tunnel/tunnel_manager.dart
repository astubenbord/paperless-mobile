import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tunnel_channel.dart';

enum TunnelConnectionState { off, connecting, connected, error }

class TunnelViewState {
  const TunnelViewState(this.state, [this.errorCode]);
  final TunnelConnectionState state;
  final String? errorCode;
}

typedef ServerProbe = Future<bool> Function(String url);

/// Coordinates automatic tunnel use. Configuration contents stay in native storage.
class TunnelManager with WidgetsBindingObserver {
  TunnelManager(
    this.channel,
    this.preferences, {
    ServerProbe? probe,
    this.pollInterval = const Duration(milliseconds: 500),
    this.connectTimeout = const Duration(seconds: 15),
    this.delayUnit = const Duration(minutes: 1),
  }) : probe = probe ?? probeServer;

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
      if (!enabled || !await channel.hasConfig()) return;
      if (directCheck && await probe(url)) return;
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
    WidgetsBinding.instance.removeObserver(this);
    state.dispose();
  }

  static Future<bool> probeServer(String url) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
    try {
      final request = await client
          .headUrl(Uri.parse(url))
          .timeout(const Duration(seconds: 2));
      final response = await request.close().timeout(
        const Duration(seconds: 2),
      );
      response.listen((_) {}).cancel();
      return true;
    } on HandshakeException {
      return true;
    } on TlsException {
      return true;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    } finally {
      client.close(force: true);
    }
  }
}
