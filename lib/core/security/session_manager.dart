import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:paperless_mobile/core/model/client_certificate.dart';

abstract interface class SessionManager implements ChangeNotifier {
  Dio get client;

  void updateSettings({
    String? baseUrl,
    String? authToken,
    ClientCertificate? clientCertificate,
  });
  void resetSettings();
}
