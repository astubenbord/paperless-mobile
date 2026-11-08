import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:paperless_mobile/constants.dart';

class ApiVersionHeaderInterceptor extends Interceptor {
  /// Set this key in [RequestOptions.extra] to send the request without
  /// resolving the api version first (e.g. for the request which determines
  /// the api version itself).
  static const skipApiVersionKey = 'skipApiVersion';

  final Future<int?> Function() getApiVersion;
  ApiVersionHeaderInterceptor(this.getApiVersion);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final apiVersion = options.extra[skipApiVersionKey] == true
        ? null
        : await getApiVersion();
    if (apiVersion != null) {
      // Always pin the api version, otherwise the server responds with its
      // default (latest) version, which might contain breaking changes.
      final effectiveApiVersion = min(
        max(minSupportedApiVersion, apiVersion),
        latestSupportedApiVersion,
      );

      options.headers[HttpHeaders.acceptHeader] =
          'application/json; version=$effectiveApiVersion';
    } else {
      options.headers[HttpHeaders.acceptHeader] = 'application/json';
    }

    handler.next(options);
  }
}
