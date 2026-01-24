import 'dart:typed_data';

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/services.dart';

/// Minimal Android KeyChain bridge.
///
/// This lets the user pick a client certificate that is already installed in the
/// Android system credential store ("VPN and apps") and then use that key for
/// mutual TLS via a native OkHttp client.
class AndroidKeyChain {
  static const MethodChannel _channel = MethodChannel('paperless_mobile/android_keychain');

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Opens the Android certificate picker and returns the selected alias.
  ///
  /// If [host] and [port] are provided, Android may filter shown certificates.
  static Future<String?> selectClientCertificateAlias({String? host, int? port}) async {
    if (!isSupported) return null;
    final alias = await _channel.invokeMethod<String>('selectClientCertificate', {
      'host': host,
      'port': port,
    });
    return alias;
  }

  /// Returns a human-readable subject for the selected alias (best effort).
  static Future<String?> getCertificateSubject(String alias) async {
    if (!isSupported) return null;
    return await _channel.invokeMethod<String>('getCertificateSubject', {
      'alias': alias,
    });
  }

  /// Performs an HTTP request using OkHttp configured to use the given KeyChain
  /// alias for mutual TLS.
  ///
  /// Returns a map: {statusCode:int, reasonPhrase:String?, headers:Map<String,List<String>>, body:Uint8List}
  static Future<Map<String, dynamic>> httpRequest({
    required String alias,
    required String method,
    required String url,
    required Map<String, String> headers,
    Uint8List? body,
    Duration? connectTimeout,
    Duration? readTimeout,
    Duration? writeTimeout,
    bool followRedirects = true,
  }) async {
    if (!isSupported) {
      throw StateError('AndroidKeyChain.httpRequest called on non-Android platform');
    }

    final result = await _channel.invokeMethod<Map>('httpRequest', {
      'alias': alias,
      'method': method,
      'url': url,
      'headers': headers,
      'body': body,
      'connectTimeoutMs': connectTimeout?.inMilliseconds,
      'readTimeoutMs': readTimeout?.inMilliseconds,
      'writeTimeoutMs': writeTimeout?.inMilliseconds,
      'followRedirects': followRedirects,
    });

    if (result == null) {
      throw StateError('Null response from native httpRequest');
    }

    // The platform channel returns a Map<dynamic, dynamic>; normalize.
    final normalized = <String, dynamic>{};
    result.forEach((k, v) => normalized[k.toString()] = v);
    return normalized;
  }
}
