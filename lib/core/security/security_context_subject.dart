import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http/io_client.dart';
import 'package:http_interceptor/http_interceptor.dart';
import 'package:paperless_mobile/features/login/model/client_certificate.dart';
import 'package:rxdart/rxdart.dart';

extension SecurityContextAwareBaseClientSubjectExtension
    on BehaviorSubject<BaseClient> {
  ///
  /// Registers new security context in a new [HttpClient].
  ///

  BaseClient _createSecurityContextAwareHttpClient(
    SecurityContext context, {
    List<InterceptorContract> interceptors = const [],
  }) {
    Dio(BaseOptions());
    return InterceptedClient.build(
      client: IOClient(HttpClient(context: context)),
      interceptors: interceptors,
    );
  }
}
