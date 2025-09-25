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
    String? code,
  }) async {
    try {
      final Map<String, dynamic> body = {
        "username": username,
        "password": password,
      };
      if (code != null && code.isNotEmpty) {
        body["code"] = code;
      }
      final response = await client.post(
        "/api/token/",
        data: body,
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
}
