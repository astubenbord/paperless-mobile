import 'dart:io';

import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/interceptor/dio_http_error_interceptor.dart';
import 'package:paperless_mobile/core/interceptor/retry_on_connection_change_interceptor.dart';
import 'package:paperless_mobile/features/login/model/client_certificate.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class SessionManager {
  final Dio client;
  final List<Interceptor> interceptors;
  PaperlessServerInformationModel serverInformation;

  SessionManager([this.interceptors = const []])
      : client = _initDio(interceptors),
        serverInformation = PaperlessServerInformationModel();

  static Dio _initDio(List<Interceptor> interceptors) {
    //en- and decoded by utf8 by default
    final Dio dio = Dio(BaseOptions());
    dio.options.receiveTimeout = const Duration(seconds: 25).inMilliseconds;
    dio.options.responseType = ResponseType.json;
    (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
        (client) => client..badCertificateCallback = (cert, host, port) => true;
    dio.interceptors.addAll([
      ...interceptors,
      DioHttpErrorInterceptor(),
      PrettyDioLogger(
        compact: true,
        responseBody: false,
        responseHeader: false,
        request: false,
        requestBody: false,
        requestHeader: false,
      ),
      RetryOnConnectionChangeInterceptor(dio: dio)
    ]);
    return dio;
  }

  void updateSettings({
    String? baseUrl,
    String? authToken,
    ClientCertificate? clientCertificate,
    PaperlessServerInformationModel? serverInformation,
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

    if (serverInformation != null) {
      this.serverInformation = serverInformation;
    }
  }

  void resetSettings() {
    client.httpClientAdapter = DefaultHttpClientAdapter();
    client.options.baseUrl = '';
    client.options.headers.remove('Authorization');
    serverInformation = PaperlessServerInformationModel();
  }
}
