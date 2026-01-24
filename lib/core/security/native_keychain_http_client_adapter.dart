import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import 'android_keychain.dart';

/// Dio HttpClientAdapter that delegates network calls to Android OkHttp,
/// configured to use a KeyChain private key + certificate chain by alias.
///
/// This is required because dart:io [SecurityContext] cannot use Android
/// Keystore/KeyChain private keys directly.
class NativeKeyChainHttpClientAdapter implements HttpClientAdapter {
  final String alias;

  NativeKeyChainHttpClientAdapter({required this.alias});

  bool _closed = false;

  @override
  void close({bool force = false}) {
    _closed = true;
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future? cancelFuture,
  ) async {
    if (_closed) {
      throw StateError('NativeKeyChainHttpClientAdapter is closed');
    }

    // Collect request body bytes (if any)
    Uint8List? body;
    if (requestStream != null) {
      final builder = BytesBuilder(copy: false);
      await for (final chunk in requestStream) {
        builder.add(chunk);
      }
      body = builder.takeBytes();
    }

    // Dio headers can contain dynamic values; normalize to strings.
    final headers = <String, String>{};
    options.headers.forEach((key, value) {
      if (value == null) return;
      if (value is List) {
        headers[key] = value.map((e) => e.toString()).join(',');
      } else {
        headers[key] = value.toString();
      }
    });

    final connectTimeout = options.connectTimeout;
    final receiveTimeout = options.receiveTimeout;
    final sendTimeout = options.sendTimeout;

    try {
      final result = await AndroidKeyChain.httpRequest(
        alias: alias,
        method: options.method,
        url: options.uri.toString(),
        headers: headers,
        body: body,
        connectTimeout: connectTimeout,
        readTimeout: receiveTimeout,
        writeTimeout: sendTimeout,
        followRedirects: options.followRedirects,
      );

      final statusCode = (result['statusCode'] as num).toInt();
      final reason = result['reasonPhrase']?.toString();

      // Headers come back as Map<String, dynamic> where each value is a List.
      final rawHeaders = <String, List<String>>{};
      final dynamic headersMap = result['headers'];
      if (headersMap is Map) {
        headersMap.forEach((k, v) {
          final key = k.toString();
          if (v is List) {
            rawHeaders[key] = v.map((e) => e.toString()).toList();
          } else if (v != null) {
            rawHeaders[key] = [v.toString()];
          }
        });
      }

      Uint8List responseBytes = Uint8List(0);
      final dynamic bodyValue = result['body'];
      if (bodyValue is Uint8List) {
        responseBytes = bodyValue;
      } else if (bodyValue is List) {
        responseBytes = Uint8List.fromList(bodyValue.cast<int>());
      } else if (bodyValue is String) {
        // For safety: accept base64 string too.
        responseBytes = base64Decode(bodyValue);
      }

      return ResponseBody.fromBytes(
        responseBytes,
        statusCode,
        statusMessage: reason,
        headers: rawHeaders,
      );
    } on PlatformException catch (e) {
      // Surface as a DioException so existing interceptors work.
      throw DioException(
        requestOptions: options,
        error: e,
        type: DioExceptionType.unknown,
        message: e.message,
      );
    } catch (e) {
      throw DioException(
        requestOptions: options,
        error: e,
        type: DioExceptionType.unknown,
        message: e.toString(),
      );
    }
  }
}
