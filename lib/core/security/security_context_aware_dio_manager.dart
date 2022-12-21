import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:paperless_mobile/core/type/types.dart';
import 'package:paperless_mobile/features/login/model/client_certificate.dart';

///
/// Convenience http client handling timeouts.
///
class SecurityContextAwareDioManager {
  final Dio _dio;
  // Some dependencies require an [HttpClient], therefore this is also maintained here.
  final HttpClient _httpClient;
  SecurityContextAwareDioManager()
      : _dio = _initDio(),
        _httpClient = HttpClient();

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
        (client) => client
          ..badCertificateCallback =
              (X509Certificate cert, String host, int port) => true;
    dio.interceptors.add(
      //TODO: Refactor, create own class...
      InterceptorsWrapper(
        onError: (e, handler) {
          //TODO: Implement and debug how error handling works, or if request has to be resolved.
          if (e.response?.statusCode == 400) {
            // try to parse contained error message, otherwise return response
            final JSON json = jsonDecode(e.response?.data);
            final PaperlessValidationErrors errorMessages = {};
            for (final entry in json.entries) {
              if (entry.value is List) {
                errorMessages.putIfAbsent(entry.key,
                    () => (entry.value as List).cast<String>().first);
              } else if (entry.value is String) {
                errorMessages.putIfAbsent(entry.key, () => entry.value);
              } else {
                errorMessages.putIfAbsent(
                    entry.key, () => entry.value.toString());
              }
            }
            throw errorMessages;
          }
          handler.next(e);
        },
      ),
    );
    return dio;
  }

  void updateSettings({
    String? baseUrl,
    String? authToken,
    ClientCertificate? clientCertificate,
  }) {
    if (clientCertificate != null) {
      final sc = SecurityContext()
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
      (_dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
          (client) => HttpClient(
                context: sc,
              )..badCertificateCallback =
                  (X509Certificate cert, String host, int port) => true;
      _securityContextStreamController.add(sc);
    }
    if (baseUrl != null) {
      _dio.options.baseUrl = baseUrl;
    }
    if (authToken != null) {
      _dio.options.headers.addAll({'Authorization': 'Token $authToken'});
    }
  }
}
