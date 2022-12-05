import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:paperless_api/src/models/paperless_server_exception.dart';
import 'package:paperless_api/src/modules/authentication_api/authentication_api.dart';

class PaperlessAuthenticationApiImpl implements PaperlessAuthenticationApi {
  final BaseClient client;

  PaperlessAuthenticationApiImpl(this.client);

  @override
  Future<String> login({
    required String username,
    required String password,
  }) async {
    late Response response;
    try {
      response = await client.post(
        Uri.parse("/api/token/"),
        body: {
          "username": username,
          "password": password,
        },
      );
    } on FormatException catch (e) {
      final source = e.source;
      if (source is String &&
          source.contains("400 No required SSL certificate was sent")) {
        throw PaperlessServerException(
          ErrorCode.missingClientCertificate,
          httpStatusCode: response.statusCode,
        );
      }
    }
    if (response.statusCode == HttpStatus.ok) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['token'];
    } else if (response.statusCode == HttpStatus.badRequest &&
        response.body
            .toLowerCase()
            .contains("no required certificate was sent")) {
      throw PaperlessServerException(
        ErrorCode.invalidClientCertificateConfiguration,
        httpStatusCode: response.statusCode,
      );
    } else {
      throw PaperlessServerException(
        ErrorCode.authenticationFailed,
        httpStatusCode: response.statusCode,
      );
    }
  }
}
