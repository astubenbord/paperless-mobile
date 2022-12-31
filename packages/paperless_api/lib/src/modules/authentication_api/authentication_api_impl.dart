import 'dart:developer';

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
    } on DioError catch (error) {
      if (error.error is ErrorCode) {
        throw PaperlessServerException(
          error.error,
          httpStatusCode: error.response?.statusCode,
        );
      } else {
        log(error.message);
        throw PaperlessServerException(
          ErrorCode.authenticationFailed,
          details: error.message,
        );
      }
    }

    if (response.statusCode == 200) {
      return response.data['token'];
    } else {
      throw PaperlessServerException(
        ErrorCode.authenticationFailed,
        httpStatusCode: response.statusCode,
      );
    }
  }
}
