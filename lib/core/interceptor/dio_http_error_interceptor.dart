import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:paperless_mobile/core/type/types.dart';

class DioHttpErrorInterceptor implements InterceptorsWrapper {
  @override
  void onError(DioError e, ErrorInterceptorHandler handler) {
    //TODO: Implement and debug how error handling works, or if request has to be resolved.
    if (e.response?.statusCode == 400) {
      // try to parse contained error message, otherwise return response
      final Map<String, dynamic> json = jsonDecode(e.response?.data);
      final PaperlessValidationErrors errorMessages = {};
      for (final entry in json.entries) {
        if (entry.value is List) {
          errorMessages.putIfAbsent(
              entry.key, () => (entry.value as List).cast<String>().first);
        } else if (entry.value is String) {
          errorMessages.putIfAbsent(entry.key, () => entry.value);
        } else {
          errorMessages.putIfAbsent(entry.key, () => entry.value.toString());
        }
      }
      throw errorMessages;
    }
    handler.next(e);
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }
}
