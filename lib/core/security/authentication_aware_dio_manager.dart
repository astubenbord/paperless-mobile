import 'dart:async';
import 'dart:io';

import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:paperless_mobile/core/interceptor/retry_on_connection_change_interceptor.dart';
import 'package:paperless_mobile/extensions/security_context_extension.dart';
import 'package:paperless_mobile/features/login/model/client_certificate.dart';

class AuthenticationAwareDioManager {
  final Dio client;
  final List<Interceptor> interceptors;

  /// Some dependencies require an [HttpClient], therefore this is also maintained here.

  AuthenticationAwareDioManager([this.interceptors = const []])
      : client = _initDio(interceptors);

  static Dio _initDio(List<Interceptor> interceptors) {
    //en- and decoded by utf8 by default
    final Dio dio = Dio(BaseOptions());
    dio.options.receiveTimeout = const Duration(seconds: 25).inMilliseconds;
    dio.options.responseType = ResponseType.json;
    (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
        (client) => client..badCertificateCallback = (cert, host, port) => true;
    dio.interceptors.addAll(interceptors);
    dio.interceptors.add(RetryOnConnectionChangeInterceptor(dio: dio));
    return dio;
  }

  void updateSettings({
    String? baseUrl,
    String? authToken,
    ClientCertificate? clientCertificate,
  }) {
    if (clientCertificate != null) {
      final context = SecurityContext()
        ..usePrivateKeyBytes(
          clientCertificate.bytes,
          password: clientCertificate.passphrase,
        )
        ..useCertificateChainBytes(
          clientCertificate.bytes,
          password: clientCertificate.passphrase,
        )
        ..setTrustedCertificatesBytes(
          clientCertificate.bytes,
          password: clientCertificate.passphrase,
        );
      final adapter = DefaultHttpClientAdapter()
        ..onHttpClientCreate = (client) => HttpClient(context: context)
          ..badCertificateCallback =
              (X509Certificate cert, String host, int port) => true;

      client.httpClientAdapter = adapter;
    }

    if (baseUrl != null) {
      client.options.baseUrl = baseUrl;
    }

    if (authToken != null) {
      client.options.headers.addAll({'Authorization': 'Token $authToken'});
    }
  }

  void resetSettings() {
    client.httpClientAdapter = DefaultHttpClientAdapter();
    client.options.baseUrl = '';
    client.options.headers.remove('Authorization');
  }
}
