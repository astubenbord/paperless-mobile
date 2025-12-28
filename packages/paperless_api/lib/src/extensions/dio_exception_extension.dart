import 'package:dio/dio.dart';
import 'package:paperless_api/src/models/paperless_api_exception.dart';

extension DioExceptionUnravelExtension on DioException {
  Object unravel({Object? orElse}) {
    if (response?.data is Map) {
      final errors = (response!.data as Map)['non_field_errors'];
      if (errors != null && errors is List && errors.isNotEmpty) {
        final errorMsg = errors.first.toString();
        if (errorMsg.contains('MFA code is required')) {
          return PaperlessMfaRequiredException();
        }
        if (errorMsg.contains('Invalid MFA code')) {
          return PaperlessApiException(
            ErrorCode.invalidMfaCode,
            details: errorMsg,
          );
        }
      }
    }
    return error ?? orElse ?? Exception("Unknown");
  }
}
