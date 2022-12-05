import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:paperless_mobile/core/interceptor/authentication.interceptor.dart';
import 'package:paperless_mobile/core/interceptor/base_url_interceptor.dart';
import 'package:paperless_mobile/core/interceptor/language_header.interceptor.dart';
import 'package:paperless_mobile/core/interceptor/response_conversion.interceptor.dart';
import 'package:http/http.dart';
import 'package:http/io_client.dart';
import 'package:http_interceptor/http/http.dart';
import 'package:injectable/injectable.dart';
import 'package:local_auth/local_auth.dart';

@module
abstract class RegisterModule {
  @prod
  @singleton
  LocalAuthentication get localAuthentication => LocalAuthentication();

  @prod
  @singleton
  EncryptedSharedPreferences get encryptedSharedPreferences =>
      EncryptedSharedPreferences();

  @prod
  @test
  @singleton
  @Order(-1)
  SecurityContext get securityContext => SecurityContext();

  @prod
  @singleton
  Connectivity get connectivity => Connectivity();

  ///
  /// Factory method creating an [HttpClient] with the currently registered [SecurityContext].
  ///
  @prod
  @Order(-1)
  HttpClient getHttpClient(SecurityContext securityContext) =>
      HttpClient(context: securityContext)
        ..connectionTimeout = const Duration(seconds: 10);

  ///
  /// Factory method creating a [InterceptedClient] on top of the currently registered [HttpClient].
  ///
  @prod
  @Order(-1)
  BaseClient getBaseClient(
    AuthenticationInterceptor authInterceptor,
    ResponseConversionInterceptor responseConversionInterceptor,
    LanguageHeaderInterceptor languageHeaderInterceptor,
    BaseUrlInterceptor baseUrlInterceptor,
    HttpClient client,
  ) =>
      InterceptedClient.build(
        interceptors: [
          baseUrlInterceptor,
          authInterceptor,
          responseConversionInterceptor,
          languageHeaderInterceptor,
        ],
        client: IOClient(client),
      );

  @prod
  CacheManager getCacheManager(BaseClient client) => CacheManager(
      Config('cacheKey', fileService: HttpFileService(httpClient: client)));
}
