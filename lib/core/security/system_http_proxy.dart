import 'dart:io';

import 'package:flutter/services.dart';
import 'package:native_flutter_proxy/native_flutter_proxy.dart';
import 'package:paperless_mobile/features/logging/data/logger.dart';

/// Process-wide system HTTP proxy applied to every dart:io [HttpClient]
/// (including Dio) via [HttpOverrides].
///
/// Dart does not read Android/iOS system proxy settings on its own.
/// Native config is stored here; [findProxy] runs per request so a later
/// system-proxy change is picked up by already-created clients.
abstract final class SystemHttpProxy {
  static String? host;
  static int? port;

  static bool get isConfigured {
    final configuredHost = host;
    final configuredPort = port;
    return configuredHost != null &&
        configuredHost.isNotEmpty &&
        configuredPort != null &&
        configuredPort > 0;
  }

  static void apply({required String? host, required int? port}) {
    SystemHttpProxy.host = host;
    SystemHttpProxy.port = port;
  }

  static void clear() {
    host = null;
    port = null;
  }

  /// PAC-style proxy string for [HttpClient.findProxy].
  static String findProxy(Uri uri) {
    if (_isLoopback(uri.host)) {
      return 'DIRECT';
    }
    if (isConfigured) {
      return 'PROXY $host:$port';
    }
    return HttpClient.findProxyFromEnvironment(uri);
  }

  static bool _isLoopback(String host) {
    if (host.isEmpty) {
      return false;
    }
    if (host.toLowerCase() == 'localhost') {
      return true;
    }
    return InternetAddress.tryParse(host)?.isLoopback ?? false;
  }

  /// Socket destination for [HttpClient.connectionFactory].
  ///
  /// When a proxy is set, connect to the proxy only. Dart's default client
  /// DNS-looks up the request host first, which hangs on networks that only
  /// resolve through the proxy.
  static ({String host, int port, bool tlsToTarget}) socketTarget(
    Uri uri,
    String? proxyHost,
    int? proxyPort,
  ) {
    if (proxyHost != null &&
        proxyHost.isNotEmpty &&
        proxyPort != null &&
        proxyPort > 0) {
      return (host: proxyHost, port: proxyPort, tlsToTarget: false);
    }
    final isSecure = uri.isScheme('https');
    var port = uri.port;
    if (port == 0) {
      port = isSecure
          ? HttpClient.defaultHttpsPort
          : HttpClient.defaultHttpPort;
    }
    return (host: uri.host, port: port, tlsToTarget: isSecure);
  }
}

/// Installs [HttpOverrides.global] and reads the OS proxy.
///
/// Must run after [logger] is initialized and before the first HTTP request.
/// PAC-based Android proxies arrive via
/// [NativeProxyReader.setProxyChangedCallback], not the initial read.
Future<void> installSystemHttpProxy() async {
  HttpOverrides.global = SystemHttpProxyOverrides();
  try {
    _applyNativeSetting(await NativeProxyReader.proxySetting);
    NativeProxyReader.setProxyChangedCallback((settings) async {
      _applyNativeSetting(settings);
    });
  } on MissingPluginException {
    // Tests and platforms without the plugin still honor http_proxy env vars.
  } catch (error, stackTrace) {
    logger.fe(
      'Failed to read system HTTP proxy.',
      className: 'SystemHttpProxy',
      methodName: 'installSystemHttpProxy',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

void _applyNativeSetting(ProxySetting settings) {
  if (settings.enabled) {
    SystemHttpProxy.apply(host: settings.host, port: settings.port);
    logger.fi(
      'Using system HTTP proxy ${settings.host}:${settings.port}',
      className: 'SystemHttpProxy',
      methodName: '_applyNativeSetting',
    );
  } else {
    if (SystemHttpProxy.isConfigured) {
      logger.fi(
        'Cleared system HTTP proxy.',
        className: 'SystemHttpProxy',
        methodName: '_applyNativeSetting',
      );
    }
    SystemHttpProxy.clear();
  }
}

class SystemHttpProxyOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..findProxy = SystemHttpProxy.findProxy
      ..connectionFactory = (uri, proxyHost, proxyPort) {
        final target = SystemHttpProxy.socketTarget(uri, proxyHost, proxyPort);
        if (target.tlsToTarget) {
          // DIRECT https: dart:io has no getter for badCertificateCallback,
          // so this path uses default cert checks. Proxied https still uses
          // the client's callback inside CONNECT/TLS (SessionManager sets it).
          return SecureSocket.startConnect(
            target.host,
            target.port,
            context: context,
          );
        }
        return Socket.startConnect(target.host, target.port);
      };
  }
}
