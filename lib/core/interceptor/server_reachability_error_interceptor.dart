import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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

    // Debug: Log all errors to understand what we're getting
    debugPrint('ServerReachabilityInterceptor - Error type: ${error.runtimeType}');
    debugPrint('ServerReachabilityInterceptor - Error: $error');

    // Detect TLS handshake failures that indicate missing client certificate
    if (error is HandshakeException) {
      final message = (error.message ?? '').toLowerCase();

      // Log all handshake failures for debugging
      debugPrint('TLS handshake failed: ${error.message}');

      // Only match on strong signals that specifically indicate missing client cert
      // Avoid false positives from general TLS failures (bad server cert, version mismatch, etc.)
      if (message.contains('certificate required') ||
          message.contains('certificate was expected') ||
          message.contains('tlsv13 alert certificate required') ||
          message.contains('bad certificate')) {
        debugPrint('DETECTED MISSING CLIENT CERTIFICATE - emitting ReachabilityStatus.missingClientCertificate');
        return _rejectWithStatus(
          ReachabilityStatus.missingClientCertificate,
          err,
          handler,
        );
      }
    }

    if (error is SocketException) {
      final code = error.osError?.errorCode;
      if (code == OsErrorCodes.serverUnreachable.code ||
          code == OsErrorCodes.hostNotFound.code) {
        return _rejectWithStatus(
          ReachabilityStatus.unknownHost,
          err,
          handler,
        );
      }
    }
    return _rejectWithStatus(
      ReachabilityStatus.notReachable,
      err,
      handler,
    );
  }
}

void _rejectWithStatus(
  ReachabilityStatus reachabilityStatus,
  DioException err,
  ErrorInterceptorHandler handler,
) {
  handler.reject(DioException(
    error: reachabilityStatus,
    requestOptions: err.requestOptions,
    response: err.response,
    type: DioExceptionType.unknown,
  ));
}
