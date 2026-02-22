import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class RetryOnConnectionChangeInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;

  RetryOnConnectionChangeInterceptor({
    required this.dio,
    this.maxRetries = 3,
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRetry(err)) {
      final retryCount = err.requestOptions.extra['retryCount'] as int? ?? 0;
      if (retryCount < maxRetries) {
        final delay = Duration(milliseconds: 500 * (1 << retryCount)); // 500ms, 1s, 2s
        if (kDebugMode) {
          debugPrint(
            '[Retry] Attempt ${retryCount + 1}/$maxRetries after ${delay.inMilliseconds}ms '
            'for ${err.requestOptions.method} ${err.requestOptions.path}',
          );
        }
        await Future.delayed(delay);
        try {
          err.requestOptions.extra['retryCount'] = retryCount + 1;
          final response = await _retry(err.requestOptions);
          handler.resolve(response);
          return;
        } catch (e) {
          // Fall through to handler.next
        }
      }
    }
    handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    // Retry on connection errors (network flakes, VPN reconnects)
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      return true;
    }
    // Retry on connection closed / socket errors
    if (err.type == DioExceptionType.unknown && err.error is SocketException) {
      return true;
    }
    if (err.type == DioExceptionType.unknown && err.error is HttpException) {
      return true;
    }
    // Retry on 502/503/504 (server temporarily unavailable)
    final statusCode = err.response?.statusCode;
    if (statusCode != null && (statusCode == 502 || statusCode == 503 || statusCode == 504)) {
      return true;
    }
    return false;
  }

  Future<Response> _retry(RequestOptions requestOptions) {
    return dio.request(
      requestOptions.path,
      cancelToken: requestOptions.cancelToken,
      data: requestOptions.data,
      onReceiveProgress: requestOptions.onReceiveProgress,
      onSendProgress: requestOptions.onSendProgress,
      queryParameters: requestOptions.queryParameters,
      options: Options(
        contentType: requestOptions.contentType,
        headers: requestOptions.headers,
        sendTimeout: requestOptions.sendTimeout,
        receiveTimeout: requestOptions.receiveTimeout,
        extra: requestOptions.extra,
        followRedirects: requestOptions.followRedirects,
        listFormat: requestOptions.listFormat,
        maxRedirects: requestOptions.maxRedirects,
        method: requestOptions.method,
        receiveDataWhenStatusError: requestOptions.receiveDataWhenStatusError,
        requestEncoder: requestOptions.requestEncoder,
        responseDecoder: requestOptions.responseDecoder,
        responseType: requestOptions.responseType,
        validateStatus: requestOptions.validateStatus,
      ),
    );
  }
}
