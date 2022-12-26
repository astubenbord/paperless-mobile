import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:http_interceptor/http_interceptor.dart';

class AuthenticationInterceptor implements InterceptorContract {
  String? serverUrl;
  String? token;
  AuthenticationInterceptor({this.serverUrl, this.token});

  @override
  Future<BaseRequest> interceptRequest({required BaseRequest request}) async {
    if (kDebugMode) {
      log("Intercepted ${request.method} request to ${request.url.toString()}");
    }

    return request.copyWith(
      url: Uri.parse((serverUrl ?? '') + request.url.toString()),
      headers: token?.isEmpty ?? true
          ? request.headers
          : {
              ...request.headers,
              'Authorization': 'Token $token',
            },
    );
  }

  @override
  Future<BaseResponse> interceptResponse(
          {required BaseResponse response}) async =>
      response;

  @override
  Future<bool> shouldInterceptRequest() async => true;

  @override
  Future<bool> shouldInterceptResponse() async => true;
}
