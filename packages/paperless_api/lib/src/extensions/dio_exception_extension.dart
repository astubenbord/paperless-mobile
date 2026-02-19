import 'package:dio/dio.dart';
import 'package:paperless_api/src/models/paperless_api_exception.dart';

extension DioExceptionUnravelExtension on DioException {
  Object unravel({Object? orElse}) {
    // Check for HTTP 413 (Request Entity Too Large)
    if (response?.statusCode == 413) {
      return const PaperlessApiException(
        ErrorCode.fileTooLarge,
        details: 'The file is too large for the server to accept.',
        httpStatusCode: 413,
      );
    }
    // Check for MFA-related errors in the response
    if (response?.statusCode == 400 || response?.statusCode == 403) {
      final data = response?.data;
      if (data is Map<String, dynamic>) {
        final errorMsg = data.values.join(' ').toLowerCase();
        if (errorMsg.contains('mfa') && errorMsg.contains('required')) {
          return const PaperlessMfaRequiredException();
        }
        if (errorMsg.contains('invalid') && errorMsg.contains('mfa')) {
          return const PaperlessApiException(ErrorCode.invalidMfaCode);
        }
      }
    }
    return error ?? orElse ?? Exception("Unknown");
  }
}
