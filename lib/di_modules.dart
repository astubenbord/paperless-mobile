import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/interceptor/authentication.interceptor.dart';
import 'package:paperless_mobile/core/interceptor/language_header.interceptor.dart';
import 'package:paperless_mobile/core/interceptor/response_conversion.interceptor.dart';
import 'package:http/http.dart';
import 'package:http/io_client.dart';
import 'package:http_interceptor/http/http.dart';
import 'package:injectable/injectable.dart';
import 'package:local_auth/local_auth.dart';

@module
abstract class RegisterModule {
  @singleton
  @dev
  @prod
  LocalAuthentication get localAuthentication => LocalAuthentication();

  @singleton
  @dev
  @prod
  EncryptedSharedPreferences get encryptedSharedPreferences =>
      EncryptedSharedPreferences();

  @singleton
  @dev
  @prod
  @test
  SecurityContext get securityContext => SecurityContext();

  @singleton
  @dev
  @prod
  Connectivity get connectivity => Connectivity();

  ///
  /// Factory method creating an [HttpClient] with the currently registered [SecurityContext].
  ///
  @injectable
  @dev
  @prod
  HttpClient getHttpClient(SecurityContext securityContext) =>
      HttpClient(context: securityContext)
        ..connectionTimeout = const Duration(seconds: 10);

  ///
  /// Factory method creating a [InterceptedClient] on top of the currently registered [HttpClient].
  ///
  @injectable
  @dev
  @prod
  BaseClient getBaseClient(
    AuthenticationInterceptor authInterceptor,
    ResponseConversionInterceptor responseConversionInterceptor,
    LanguageHeaderInterceptor languageHeaderInterceptor,
    HttpClient client,
  ) =>
      InterceptedClient.build(
        interceptors: [
          authInterceptor,
          responseConversionInterceptor,
          languageHeaderInterceptor
        ],
        client: IOClient(client),
      );

  @injectable
  @dev
  @prod
  CacheManager getCacheManager(BaseClient client) => CacheManager(
      Config('cacheKey', fileService: HttpFileService(httpClient: client)));

  @injectable
  @dev
  @prod
  PaperlessAuthenticationApi authenticationModule(BaseClient client) =>
      PaperlessAuthenticationApiImpl(client);

  @injectable
  @dev
  @prod
  PaperlessLabelsApi labelsModule(
    @Named('timeoutClient') BaseClient timeoutClient,
  ) =>
      PaperlessLabelApiImpl(timeoutClient);

  @injectable
  @dev
  @prod
  PaperlessDocumentsApi documentsModule(
    @Named('timeoutClient') BaseClient timeoutClient,
    HttpClient httpClient,
  ) =>
      PaperlessDocumentsApiImpl(timeoutClient, httpClient);

  @injectable
  @dev
  @prod
  PaperlessSavedViewsApi savedViewsModule(
    @Named('timeoutClient') BaseClient timeoutClient,
  ) =>
      PaperlessSavedViewsApiImpl(timeoutClient);

  @injectable
  @dev
  @prod
  PaperlessServerStatsApi serverStatsModule(
    @Named('timeoutClient') BaseClient timeoutClient,
  ) =>
      PaperlessServerStatsApiImpl(timeoutClient);
}
