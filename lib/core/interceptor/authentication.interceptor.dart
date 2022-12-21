import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:http_interceptor/http_interceptor.dart';
import 'package:paperless_mobile/core/store/local_vault.dart';

class AuthenticationInterceptor implements InterceptorContract {
  final LocalVault _localVault;
  AuthenticationInterceptor(this._localVault);

  @override
  Future<BaseRequest> interceptRequest({required BaseRequest request}) async {
    final auth = await _localVault.loadAuthenticationInformation();

    if (kDebugMode) {
      log("Intercepted ${request.method} request to ${request.url.toString()}");
    }

    return request.copyWith(
      //Append server Url
      headers: auth?.token?.isEmpty ?? true
          ? request.headers
          : {
              ...request.headers,
              'Authorization': 'Token ${auth!.token}',
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
