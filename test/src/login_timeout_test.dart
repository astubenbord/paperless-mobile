import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:paperless_mobile/api/paperless_api.dart';
import 'package:paperless_mobile/core/interceptor/dio_offline_interceptor.dart';
import 'package:paperless_mobile/core/interceptor/server_reachability_error_interceptor.dart';
import 'package:paperless_mobile/core/security/session_manager_impl.dart';
import 'package:paperless_mobile/features/logging/data/logger.dart';
import 'package:paperless_mobile/features/login/model/reachability_status.dart';

class _FakeHttpClientAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  )
  onFetch;

  _FakeHttpClientAdapter(this.onFetch);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return onFetch(options, requestStream, cancelFuture);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUpAll(() {
    logger = Logger(level: Level.off);
  });

  group('SessionManagerImpl timeout configuration', () {
    test(
      'configures fast 5s connectTimeout and 15s receiveTimeout by default',
      () {
        final sessionManager = SessionManagerImpl();
        addTearDown(sessionManager.resetSettings);

        expect(
          sessionManager.client.options.connectTimeout,
          const Duration(seconds: 5),
        );
        expect(
          sessionManager.client.options.receiveTimeout,
          const Duration(seconds: 15),
        );
        expect(
          sessionManager.client.options.sendTimeout,
          const Duration(seconds: 10),
        );
      },
    );
  });

  group('PaperlessAuthenticationApiImpl login and token validation', () {
    test(
      'token() uses 5s sendTimeout and 30s receiveTimeout on /api/token/ and /api/profile/',
      () async {
        final sessionManager = SessionManagerImpl()
          ..updateSettings(baseUrl: 'https://paperless.example.com');
        addTearDown(sessionManager.resetSettings);

        final capturedRequests = <RequestOptions>[];
        sessionManager.client.httpClientAdapter = _FakeHttpClientAdapter((
          options,
          _,
          _,
        ) async {
          capturedRequests.add(options);
          if (options.path == '/api/token/') {
            return ResponseBody.fromString(
              jsonEncode({'token': 'secret-auth-token'}),
              HttpStatus.ok,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            );
          }
          if (options.path == '/api/profile/') {
            return ResponseBody.fromString(
              '',
              HttpStatus.ok,
              headers: {
                'x-api-version': ['9'],
              },
            );
          }
          return ResponseBody.fromString('', HttpStatus.notFound);
        });

        final authApi = PaperlessAuthenticationApiImpl(sessionManager.client);
        final result = await authApi.token(
          PaperlessAuthTokenRequest(username: 'alice', password: 'password123'),
        );

        expect(result.value, 'secret-auth-token');
        expect(result.apiVersion, 9);
        expect(capturedRequests, hasLength(2));

        final tokenReq = capturedRequests[0];
        expect(tokenReq.method, 'POST');
        expect(tokenReq.path, '/api/token/');
        expect(tokenReq.connectTimeout, const Duration(seconds: 5));
        expect(tokenReq.sendTimeout, const Duration(seconds: 5));
        expect(tokenReq.receiveTimeout, const Duration(seconds: 30));

        final profileReq = capturedRequests[1];
        expect(profileReq.method, 'HEAD');
        expect(profileReq.path, '/api/profile/');
        expect(profileReq.headers['Authorization'], 'Token secret-auth-token');
        expect(profileReq.connectTimeout, const Duration(seconds: 5));
        expect(profileReq.sendTimeout, const Duration(seconds: 5));
        expect(profileReq.receiveTimeout, const Duration(seconds: 30));
      },
    );

    test(
      'validateToken() uses 5s sendTimeout and 30s receiveTimeout on /api/profile/',
      () async {
        final sessionManager = SessionManagerImpl()
          ..updateSettings(baseUrl: 'https://paperless.example.com');
        addTearDown(sessionManager.resetSettings);

        RequestOptions? capturedOptions;
        sessionManager.client.httpClientAdapter = _FakeHttpClientAdapter((
          options,
          _,
          _,
        ) async {
          capturedOptions = options;
          return ResponseBody.fromString(
            '',
            HttpStatus.ok,
            headers: {
              'x-api-version': ['8'],
            },
          );
        });

        final authApi = PaperlessAuthenticationApiImpl(sessionManager.client);
        final result = await authApi.validateToken('api-key-123');

        expect(result.value, isTrue);
        expect(result.apiVersion, 8);
        expect(capturedOptions, isNotNull);
        expect(capturedOptions!.method, 'HEAD');
        expect(capturedOptions!.path, '/api/profile/');
        expect(capturedOptions!.connectTimeout, const Duration(seconds: 5));
        expect(capturedOptions!.sendTimeout, const Duration(seconds: 5));
        expect(capturedOptions!.receiveTimeout, const Duration(seconds: 30));
      },
    );

    test(
      'token() does not hang on receiveTimeout or connectionTimeout and throws ErrorCode.requestTimedOut',
      () async {
        for (final timeoutType in [
          DioExceptionType.connectionTimeout,
          DioExceptionType.sendTimeout,
          DioExceptionType.receiveTimeout,
        ]) {
          final sessionManager = SessionManagerImpl()
            ..updateSettings(baseUrl: 'https://paperless.example.com');
          addTearDown(sessionManager.resetSettings);

          sessionManager.client.httpClientAdapter = _FakeHttpClientAdapter((
            options,
            _,
            _,
          ) async {
            throw DioException(
              requestOptions: options,
              type: timeoutType,
              message: 'Simulated $timeoutType',
            );
          });

          final authApi = PaperlessAuthenticationApiImpl(sessionManager.client);
          await expectLater(
            authApi
                .token(
                  PaperlessAuthTokenRequest(
                    username: 'alice',
                    password: 'password123',
                  ),
                )
                .timeout(const Duration(seconds: 2)),
            throwsA(
              isA<PaperlessApiException>().having(
                (e) => e.code,
                'code',
                ErrorCode.requestTimedOut,
              ),
            ),
          );
        }
      },
    );

    test(
      'DioOfflineInterceptor forwards non-101 SocketException without hanging',
      () async {
        final sessionManager = SessionManagerImpl()
          ..updateSettings(baseUrl: 'https://paperless.example.com');
        addTearDown(sessionManager.resetSettings);

        sessionManager.client.httpClientAdapter = _FakeHttpClientAdapter((
          options,
          _,
          _,
        ) async {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
            error: const SocketException(
              'Connection refused',
              osError: OSError('Connection refused', 111),
            ),
          );
        });

        final authApi = PaperlessAuthenticationApiImpl(sessionManager.client);
        await expectLater(
          authApi
              .token(
                PaperlessAuthTokenRequest(
                  username: 'alice',
                  password: 'password123',
                ),
              )
              .timeout(const Duration(seconds: 2)),
          throwsA(isA<SocketException>()),
        );
      },
    );

    test(
      'DioOfflineInterceptor maps OSError 101 to ErrorCode.deviceOffline',
      () async {
        final dio = Dio()..interceptors.add(DioOfflineInterceptor());
        dio.httpClientAdapter = _FakeHttpClientAdapter((options, _, _) async {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
            error: const SocketException(
              'Network is unreachable',
              osError: OSError('Network is unreachable', 101),
            ),
          );
        });

        await expectLater(
          dio.get('https://paperless.example.com/api/'),
          throwsA(
            isA<DioException>().having(
              (e) => e.error,
              'error',
              isA<PaperlessApiException>().having(
                (e) => e.code,
                'code',
                ErrorCode.deviceOffline,
              ),
            ),
          ),
        );
      },
    );
  });

  group('ServerReachabilityErrorInterceptor', () {
    test(
      'maps connectionTimeout, sendTimeout, and receiveTimeout to ReachabilityStatus.connectionTimeout',
      () async {
        for (final timeoutType in [
          DioExceptionType.connectionTimeout,
          DioExceptionType.sendTimeout,
          DioExceptionType.receiveTimeout,
        ]) {
          final dio = Dio()
            ..interceptors.add(ServerReachabilityErrorInterceptor());
          dio.httpClientAdapter = _FakeHttpClientAdapter((options, _, _) async {
            throw DioException(requestOptions: options, type: timeoutType);
          });

          await expectLater(
            dio.head('https://paperless.example.com/api/schema/'),
            throwsA(
              isA<DioException>().having(
                (e) => e.error,
                'error',
                ReachabilityStatus.connectionTimeout,
              ),
            ),
          );
        }
      },
    );
  });
}

