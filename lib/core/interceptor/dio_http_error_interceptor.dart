import 'package:dio/dio.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/type/types.dart';

class DioHttpErrorInterceptor extends Interceptor {
  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 400) {
      // try to parse contained error message, otherwise return response
      final dynamic data = err.response?.data;
      if (data is Map<String, dynamic>) {
        return _handlePaperlessValidationError(data, handler, err);
      } else if (data is String) {
        return _handlePlainError(data, handler, err);
      }
    }
    handler.reject(err);
  }

  void _handlePaperlessValidationError(
    Map<String, dynamic> json,
    ErrorInterceptorHandler handler,
    DioError err,
  ) {
    final PaperlessValidationErrors errorMessages = {};
    for (final entry in json.entries) {
      if (entry.value is List) {
        errorMessages.putIfAbsent(
          entry.key,
          () => (entry.value as List).cast<String>().first,
        );
      } else if (entry.value is String) {
        errorMessages.putIfAbsent(entry.key, () => entry.value);
      } else {
        errorMessages.putIfAbsent(entry.key, () => entry.value.toString());
      }
    }
    return handler.reject(
      DioError(
        error: errorMessages,
        requestOptions: err.requestOptions,
        type: DioErrorType.response,
      ),
    );
  }

  void _handlePlainError(
    String data,
    ErrorInterceptorHandler handler,
    DioError err,
  ) {
    if (data.contains("No required SSL certificate was sent")) {
      handler.reject(
        DioError(
          requestOptions: err.requestOptions,
          type: DioErrorType.response,
          error: ErrorCode.missingClientCertificate,
        ),
      );
    }
  }
}
