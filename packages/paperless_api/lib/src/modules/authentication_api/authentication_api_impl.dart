import 'package:dio/dio.dart';
import 'package:paperless_api/src/models/paperless_server_exception.dart';
import 'package:paperless_api/src/modules/authentication_api/authentication_api.dart';

class PaperlessAuthenticationApiImpl implements PaperlessAuthenticationApi {
  final Dio client;

  PaperlessAuthenticationApiImpl(this.client);

  @override
  Future<String> login({
    required String username,
    required String password,
  }) async {
    late Response response;
    try {
      response = await client.post(
        "/api/token/",
        data: {
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
    if (response.statusCode == 200) {
      return response.data['token'];
    } else if (response.statusCode == 400 &&
        response
            .data //TODO: Check if text is included in statusMessage instead of body
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
