import 'package:dio/dio.dart';
import 'package:paperless_mobile/api/models/exception/paperless_api_exception.dart';

extension DioExceptionUnravelExtension on DioException {
  Object unravel({Object? orElse}) {
    if (type == DioExceptionType.connectionTimeout ||
        type == DioExceptionType.sendTimeout ||
        type == DioExceptionType.receiveTimeout) {
      return error ?? const PaperlessApiException(ErrorCode.requestTimedOut);
    }
    return error ?? orElse ?? Exception("Unknown");
  }
}
