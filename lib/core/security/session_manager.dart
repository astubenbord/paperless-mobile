import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:paperless_mobile/features/login/model/client_certificate.dart';
import 'package:paperless_mobile/features/login/server_connection/model/header_entry.dart';

abstract interface class SessionManager implements ChangeNotifier {
  Dio get client;

  void updateSettings({
    String? baseUrl,
    String? authToken,
    ClientCertificate? clientCertificate,
    List<HeaderEntry>? additionalHeaders,
    bool broadcast = true,
  });
  void resetSettings({bool broadcast = true});
  Future<int> getApiVersion();
}
