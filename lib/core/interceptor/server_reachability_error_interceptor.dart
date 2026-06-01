import 'dart:io';

import 'package:dio/dio.dart';
import 'package:paperless_mobile/core/global/os_error_codes.dart';
import 'package:paperless_mobile/features/login/model/reachability_status.dart';

class ServerReachabilityErrorInterceptor extends Interceptor {
  static const _missingClientCertText = "No required SSL certificate was sent";

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 400) {
      final message = err.response?.data;
      if (message is String && message.contains(_missingClientCertText)) {
        return _rejectWithStatus(
          ReachabilityStatus.missingClientCertificate,
          err,
          handler,
        );
      }
    }
    if (err.type == DioExceptionType.connectionTimeout) {
      return _rejectWithStatus(
        ReachabilityStatus.connectionTimeout,
        err,
        handler,
      );
    }
    final error = err.error;
    if (error is SocketException) {
      final code = error.osError?.errorCode;
      if (code == OsErrorCodes.serverUnreachable.code ||
          code == OsErrorCodes.hostNotFound.code) {
        return _rejectWithStatus(ReachabilityStatus.unknownHost, err, handler);
      }
    }
    return _rejectWithStatus(ReachabilityStatus.notReachable, err, handler);
  }
}

void _rejectWithStatus(
  ReachabilityStatus reachabilityStatus,
  DioException err,
  ErrorInterceptorHandler handler,
) {
  handler.reject(
    DioException(
      error: reachabilityStatus,
      requestOptions: err.requestOptions,
      response: err.response,
      type: DioExceptionType.unknown,
    ),
  );
}
