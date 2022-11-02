import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:paperless_mobile/core/model/error_message.dart';
import 'package:paperless_mobile/features/login/bloc/authentication_cubit.dart';
import 'package:http_interceptor/http_interceptor.dart';
import 'package:injectable/injectable.dart';

@injectable
class AuthenticationInterceptor implements InterceptorContract {
  AuthenticationCubit authenticationCubit;
  AuthenticationInterceptor(this.authenticationCubit);

  @override
  Future<BaseRequest> interceptRequest({required BaseRequest request}) async {
    final authState = authenticationCubit.state;
    if (kDebugMode) {
      log("Intercepted request to ${request.url.toString()}");
    }
    if (authState.authentication == null) {
      throw const ErrorMessage(ErrorCode.notAuthenticated);
    }
    return request.copyWith(
      //Append server Url
      url: Uri.parse(authState.authentication!.serverUrl + request.url.toString()),
      headers: authState.authentication!.token.isEmpty
          ? request.headers
          : {...request.headers, 'Authorization': 'Token ${authState.authentication!.token}'},
    );
  }

  @override
  Future<BaseResponse> interceptResponse({required BaseResponse response}) async => response;
}
