import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/store/local_vault.dart';
import 'package:http_interceptor/http_interceptor.dart';
import 'package:injectable/injectable.dart';

@injectable
class AuthenticationInterceptor implements InterceptorContract {
  final LocalVault _localVault;
  AuthenticationInterceptor(this._localVault);

  @override
  Future<BaseRequest> interceptRequest({required BaseRequest request}) async {
    final auth = await _localVault.loadAuthenticationInformation();

    if (kDebugMode) {
      log("Intercepted ${request.method} request to ${request.url.toString()}");
    }
    if (auth == null) {
      throw const PaperlessServerException(ErrorCode.notAuthenticated);
    }
    return request.copyWith(
      //Append server Url
      url: Uri.parse(auth.serverUrl + request.url.toString()),
      headers: auth.token.isEmpty
          ? request.headers
          : {...request.headers, 'Authorization': 'Token ${auth.token}'},
    );
  }

  @override
  Future<BaseResponse> interceptResponse(
          {required BaseResponse response}) async =>
      response;
}
