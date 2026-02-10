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
      if (totpCode != null) {
        data["code"] = totpCode;
      }
      final response = await client.post(
        "/api/token/",
        data: data,
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          followRedirects: false,
          headers: {
            "Accept": "application/json",
          },
        ),
      );
      return response.data['token'];
    } on DioException catch (exception) {
      final error = exception.error;
      if (error is PaperlessFormValidationException) {
        final message = error.unspecificErrorMessage();
        if (message != null &&
            message.contains('MFA code is required')) {
          throw PaperlessMfaRequiredException();
        }
      }
      throw exception.unravel();
    } catch (error, stackTrace) {
      throw PaperlessApiException.unknown(
        details: error.toString(),
        stackTrace: stackTrace,
      );
    }
  }
}
