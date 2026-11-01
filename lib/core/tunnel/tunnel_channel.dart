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
