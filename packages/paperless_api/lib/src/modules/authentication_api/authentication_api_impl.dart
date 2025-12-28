import 'package:dio/dio.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_api/src/extensions/dio_exception_extension.dart';

class PaperlessAuthenticationApiImpl implements PaperlessAuthenticationApi {
  final Dio client;

  PaperlessAuthenticationApiImpl(this.client);

  @override
  Future<String> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await client.post(
        "/api/token/",
        data: {
          "username": username,
          "password": password,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          followRedirects: false,
          headers: {
            "Accept": "application/json",
          },
          // validateStatus: (status) {
          //   return status! == 200;
          // },
        ),
      );
      return response.data['token'];
      // } else if (response.statusCode == 302) {
      // final redirectUrl = response.headers.value("location");
      // return AuthenticationTemporaryRedirect(redirectUrl!);
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
  Future<String> validateApiKey({
    required String apiKey,
  }) async {
    try {
      // API keys are already valid tokens, but we should validate them
      // by making a test request with the key
      await client.get(
        "/api/",
        options: Options(
          headers: {"Authorization": "Token $apiKey"},
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      return apiKey; // If successful, the API key is valid
    } on DioException catch (exception) {
      throw exception.unravel();
    } catch (error, stackTrace) {
      throw PaperlessApiException.unknown(
        details: error.toString(),
        stackTrace: stackTrace,
      );
    }
  }
}
