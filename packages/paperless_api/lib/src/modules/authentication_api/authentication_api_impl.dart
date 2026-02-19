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
    String? totpCode,
  }) async {
    try {
      final data = <String, dynamic>{
        "username": username,
        "password": password,
      };
      if (totpCode != null && totpCode.isNotEmpty) {
        data["code"] = totpCode;
      }
      final response = await client.post(
        "/api/token/",
        data: data,
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
          followRedirects: false,
          headers: {
            "Accept": "application/json",
          },
        ),
      );
      return response.data['token'];
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
  Future<bool> validateApiKey(String apiKey) async {
    try {
      final response = await client.get(
        "/api/ui_settings/",
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
          headers: {
            "Accept": "application/json",
            "Authorization": "Token $apiKey",
          },
          validateStatus: (status) => status == 200 || status == 403,
        ),
      );
      return response.statusCode == 200;
    } on DioException catch (exception) {
      throw exception.unravel(
        orElse: const PaperlessApiException(ErrorCode.invalidApiKey),
      );
    }
  }
}
