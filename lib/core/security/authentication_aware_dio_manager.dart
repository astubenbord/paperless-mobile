import 'dart:async';
import 'dart:io';

import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:paperless_mobile/core/interceptor/dio_http_error_interceptor.dart';
import 'package:paperless_mobile/extensions/security_context_extension.dart';
import 'package:paperless_mobile/features/login/model/client_certificate.dart';

///
/// Convenience http client handling timeouts.
///
class AuthenticationAwareDioManager {
  final Dio _dio;

  /// Some dependencies require an [HttpClient], therefore this is also maintained here.

  AuthenticationAwareDioManager() : _dio = _initDio();

  Dio get client => _dio;

  Stream<SecurityContext> get securityContextChanges =>
      _securityContextStreamController.stream.asBroadcastStream();

  final StreamController<SecurityContext> _securityContextStreamController =
      StreamController.broadcast();

  static Dio _initDio() {
    //en- and decoded by utf8 by default
    final Dio dio = Dio(BaseOptions());
    dio.options.receiveTimeout = const Duration(seconds: 25).inMilliseconds;
    dio.options.responseType = ResponseType.json;
    (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
        (client) => client..badCertificateCallback = (cert, host, port) => true;
    dio.interceptors.add(DioHttpErrorInterceptor());
    return dio;
  }

  void updateSettings({
    String? baseUrl,
    String? authToken,
    ClientCertificate? clientCertificate,
  }) {
    if (clientCertificate != null) {
      final context =
          SecurityContext().withClientCertificate(clientCertificate);
      (_dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
          (client) => HttpClient(context: context)
            ..badCertificateCallback =
                (X509Certificate cert, String host, int port) => true;
      _securityContextStreamController.add(context);
    }
    if (baseUrl != null) {
      _dio.options.baseUrl = baseUrl;
    }
    if (authToken != null) {
      _dio.options.headers.addAll({'Authorization': 'Token $authToken'});
    }
  }
}
