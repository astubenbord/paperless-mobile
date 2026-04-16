import 'dart:io';

import 'package:dio/dio.dart';
import 'package:paperless_mobile/api/models/paperless_auth_token.dart';
import 'package:paperless_mobile/api/models/response_value_with_api_version.dart';
import 'package:paperless_mobile/api/paperless_api.dart';

abstract class PaperlessAuthenticationApi {
  Future<ResponseValueWithApiVersion<String>> token(
    PaperlessAuthTokenRequest request,
  );
  Future<ResponseValueWithApiVersion<bool>> validateToken(String token);
  String getOAuthCallback();
}

class PaperlessAuthenticationApiImpl implements PaperlessAuthenticationApi {
  final Dio client;

  PaperlessAuthenticationApiImpl(this.client);

  @override
  Future<ResponseValueWithApiVersion<String>> token(
    PaperlessAuthTokenRequest request,
  ) async {
    try {
      final response = await client.post(
        "/api/token/",
        data: request.toJson(),
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          followRedirects: false,
        ),
      );

      final token = PaperlessAuthToken.fromJson(response.data).token;
      // Since the /token/ endpoint does not include the api version in the response headers,
      // we need to make an additional request to get the api version.
      final apiVersionResponse = await client.head(
        '/api/profile/',
        options: Options(
          headers: {"Authorization": "Token $token"},
          validateStatus: (status) => status == HttpStatus.ok,
        ),
      );

      final apiVersion = int.parse(
        apiVersionResponse.headers.value('x-api-version') ?? '',
      );

      return ResponseValueWithApiVersion(value: token, apiVersion: apiVersion);
    } on DioException catch (exception) {
      throw exception.unravel();
    } catch (error, stackTrace) {
      throw PaperlessApiException.unknown(
        details: error.toString(),
        stackTrace: stackTrace,
      );
    }
  }

  @override
  String getOAuthCallback() {
    return "${client.options.baseUrl}/oauth/callback/";
  }

  @override
  Future<ResponseValueWithApiVersion<bool>> validateToken(String token) async {
    try {
      final response = await client.head(
        '/api/profile/',
        options: Options(
          headers: {"Authorization": "Token $token"},
          validateStatus: (status) => status == HttpStatus.ok,
        ),
      );
      final apiVersion = int.parse(
        response.headers.value('x-api-version') ?? '',
      );

      return ResponseValueWithApiVersion(value: true, apiVersion: apiVersion);
    } catch (_) {
      throw PaperlessApiException(ErrorCode.invalidApiKey);
    }
  }
}
