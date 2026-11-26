import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_mobile/api/paperless_api.dart';

typedef _Handler =
    ResponseBody Function(RequestOptions options, String? requestBody);

/// Answers requests by "METHOD path" and records them.
class _FakeAdapter implements HttpClientAdapter {
  final Map<String, _Handler> handlers;
  final List<RequestOptions> requests = [];
  final List<String?> bodies = [];

  _FakeAdapter(this.handlers);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = requestStream == null
        ? null
        : utf8.decode(await requestStream.expand((chunk) => chunk).toList());
    requests.add(options);
    bodies.add(body);
    final handler = handlers['${options.method} ${options.uri.path}'];
    if (handler == null) {
      return _json({'detail': 'Not found'}, 404);
    }
    return handler(options, body);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(
  Object data,
  int status, {
  Map<String, List<String>> headers = const {},
}) {
  return ResponseBody.fromString(
    jsonEncode(data),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
      ...headers,
    },
  );
}

const _serverUrl = 'https://paperless.example.com';
const _idpUrl = 'https://idp.example.com';

const _provider = OidcProvider(
  id: 'idp',
  name: 'Example IdP',
  clientId: 'paperless-client',
  openidConfigurationUrl: '$_idpUrl/.well-known/openid-configuration',
);

Map<String, _Handler> _paperlessHandlers({
  _Handler? providerToken,
  String? redirectScope,
}) {
  return {
    'GET /accounts/login/': (_, _) => ResponseBody.fromString(
      '<html></html>',
      200,
      headers: {
        'set-cookie': ['csrftoken=csrf123; Path=/; SameSite=Lax'],
      },
    ),
    'POST /api/auth/headless/browser/v1/auth/provider/redirect': (_, _) =>
        ResponseBody.fromString(
          '',
          302,
          headers: {
            'location': [
              '$_idpUrl/authorize?client_id=paperless-client'
                  '&scope=${Uri.encodeQueryComponent(redirectScope ?? 'openid profile email')}',
            ],
          },
        ),
    'POST /api/auth/headless/app/v1/auth/provider/token':
        providerToken ??
        (_, _) => _json({
          'status': 200,
          'meta': {'access_token': 'paperless-token'},
        }, 200),
  };
}

Map<String, _Handler> _idpHandlers({_Handler? token}) {
  return {
    'GET /.well-known/openid-configuration': (_, _) => _json({
      'authorization_endpoint': '$_idpUrl/authorize',
      'token_endpoint': '$_idpUrl/token',
    }, 200),
    'POST /token': token ?? (_, _) => _json({'id_token': 'the-id-token'}, 200),
  };
}

/// A browser that approves the login, echoing the state of the request.
BrowserAuthenticator _approvingBrowser({
  void Function(Uri url)? onOpen,
  String? state,
  String? error,
}) {
  return ({required String url, required String callbackUrlScheme}) async {
    final uri = Uri.parse(url);
    onOpen?.call(uri);
    final params = error != null
        ? {'error': error, 'error_description': 'Denied by the user'}
        : {'code': 'auth-code', 'state': state ?? uri.queryParameters['state']};
    return Uri(
      scheme: callbackUrlScheme,
      host: 'oidc-callback',
      queryParameters: params,
    ).toString();
  };
}

({PaperlessOidcApi api, _FakeAdapter paperless, _FakeAdapter idp}) _createApi({
  Map<String, _Handler>? paperlessHandlers,
  Map<String, _Handler>? idpHandlers,
  BrowserAuthenticator? browser,
  String baseUrl = _serverUrl,
}) {
  final paperless = _FakeAdapter(paperlessHandlers ?? _paperlessHandlers());
  final idp = _FakeAdapter(idpHandlers ?? _idpHandlers());
  final paperlessClient = Dio(BaseOptions(baseUrl: baseUrl))
    ..httpClientAdapter = paperless;
  final idpClient = Dio()..httpClientAdapter = idp;
  final api = PaperlessOidcApi(
    paperlessClient,
    identityProviderClient: idpClient,
    authenticate: browser ?? _approvingBrowser(),
  );
  return (api: api, paperless: paperless, idp: idp);
}

TypeMatcher<PaperlessApiException> _apiException(ErrorCode code) =>
    isA<PaperlessApiException>().having((e) => e.code, 'code', code);

void main() {
  group('getProviders', () {
    test('returns only providers supporting the app token flow', () async {
      final (:api, :paperless, :idp) = _createApi(
        paperlessHandlers: {
          'GET /api/auth/headless/app/v1/config': (_, _) => _json({
            'status': 200,
            'data': {
              'socialaccount': {
                'providers': [
                  {
                    'id': 'pocketid',
                    'name': 'Pocket ID',
                    'flows': ['provider_redirect', 'provider_token'],
                    'client_id': 'abc',
                    'openid_configuration_url':
                        '$_idpUrl/.well-known/openid-configuration',
                  },
                  {
                    'id': 'github',
                    'name': 'GitHub',
                    'flows': ['provider_redirect'],
                  },
                  {'id': 'malformed', 'flows': 'provider_token'},
                  {
                    'id': 'token-only',
                    'flows': ['provider_token'],
                    'client_id': 'ghi',
                    'openid_configuration_url':
                        '$_idpUrl/.well-known/openid-configuration',
                  },
                  {
                    'id': 'no-discovery',
                    'flows': ['provider_redirect', 'provider_token'],
                    'client_id': 'def',
                  },
                ],
              },
            },
          }, 200),
        },
      );

      final providers = await api.getProviders();

      expect(providers, hasLength(1));
      expect(providers.single.id, 'pocketid');
      expect(providers.single.name, 'Pocket ID');
      expect(providers.single.clientId, 'abc');
    });

    test('returns an empty list when the server has no headless API', () async {
      final (:api, :paperless, :idp) = _createApi(paperlessHandlers: {});

      expect(await api.getProviders(), isEmpty);
    });
  });

  group('login', () {
    test('runs the PKCE flow and returns the Paperless-ngx token', () async {
      late Uri authorizationUrl;
      final (:api, :paperless, :idp) = _createApi(
        paperlessHandlers: _paperlessHandlers(
          redirectScope: 'openid profile email groups',
        ),
        browser: _approvingBrowser(onOpen: (url) => authorizationUrl = url),
      );

      final result = await api.login(_provider);

      expect(result, isA<OidcLoginSuccess>());
      expect((result as OidcLoginSuccess).token, 'paperless-token');

      final query = authorizationUrl.queryParameters;
      expect(query['client_id'], 'paperless-client');
      expect(query['redirect_uri'], PaperlessOidcApi.callbackUrl);
      expect(query['response_type'], 'code');
      expect(query['scope'], 'openid profile email groups');
      expect(query['code_challenge_method'], 'S256');

      final tokenBody = Uri.splitQueryString(idp.bodies.last!);
      expect(tokenBody['grant_type'], 'authorization_code');
      expect(tokenBody['code'], 'auth-code');
      expect(tokenBody.containsKey('client_secret'), isFalse);
      final challenge = base64UrlEncode(
        sha256.convert(ascii.encode(tokenBody['code_verifier']!)).bytes,
      ).replaceAll('=', '');
      expect(challenge, query['code_challenge']);

      final exchange = jsonDecode(paperless.bodies.last!) as Map;
      expect(exchange['provider'], 'idp');
      expect(exchange['token'], {
        'client_id': 'paperless-client',
        'id_token': 'the-id-token',
      });
    });

    test(
      'sends a single slash in callback_url when the base URL has one',
      () async {
        final (:api, :paperless, :idp) = _createApi(baseUrl: '$_serverUrl/');

        await api.login(_provider);

        final redirectBody =
            paperless.bodies[paperless.requests.indexWhere(
              (r) => r.uri.path.endsWith('/provider/redirect'),
            )]!;
        expect(
          Uri.splitQueryString(redirectBody)['callback_url'],
          '$_serverUrl/',
        );
      },
    );

    test('returns cancelled when the user closes the browser', () async {
      final (:api, :paperless, :idp) = _createApi(
        browser: ({required url, required callbackUrlScheme}) =>
            throw PlatformException(code: 'CANCELED'),
      );

      expect(await api.login(_provider), isA<OidcLoginCancelled>());
    });

    test('rejects a callback with a different state', () async {
      final (:api, :paperless, :idp) = _createApi(
        browser: _approvingBrowser(state: 'forged'),
      );

      await expectLater(
        api.login(_provider),
        throwsA(_apiException(ErrorCode.oidcLoginFailed)),
      );
    });

    test('returns cancelled when the user denies the consent', () async {
      final (:api, :paperless, :idp) = _createApi(
        browser: _approvingBrowser(error: 'access_denied'),
      );

      expect(await api.login(_provider), isA<OidcLoginCancelled>());
    });

    test('reports an error returned by the identity provider', () async {
      final (:api, :paperless, :idp) = _createApi(
        browser: _approvingBrowser(error: 'temporarily_unavailable'),
      );

      await expectLater(
        api.login(_provider),
        throwsA(
          _apiException(ErrorCode.oidcLoginFailed).having(
            (e) => e.details,
            'details',
            contains('temporarily_unavailable'),
          ),
        ),
      );
    });

    test('explains that a confidential client is not supported', () async {
      final (:api, :paperless, :idp) = _createApi(
        idpHandlers: _idpHandlers(
          token: (_, _) => _json({
            'error': 'invalid_client',
            'error_description': 'Client authentication failed',
          }, 401),
        ),
      );

      await expectLater(
        api.login(_provider),
        throwsA(_apiException(ErrorCode.oidcClientNotPublic)),
      );
    });

    test('does not put other tokens into the error details', () async {
      final (:api, :paperless, :idp) = _createApi(
        idpHandlers: _idpHandlers(
          token: (_, _) => _json({
            'access_token': 'secret-access-token',
            'refresh_token': 'secret-refresh-token',
          }, 200),
        ),
      );

      await expectLater(
        api.login(_provider),
        throwsA(
          _apiException(
            ErrorCode.oidcLoginFailed,
          ).having((e) => e.details, 'details', isNot(contains('secret'))),
        ),
      );
    });

    test('reports an identity provider that cannot be reached', () async {
      final (:api, :paperless, :idp) = _createApi(
        idpHandlers: {
          'GET /.well-known/openid-configuration': (options, _) =>
              throw DioException.connectionError(
                requestOptions: options,
                reason: 'Connection refused',
                error: const SocketException('Connection refused'),
              ),
        },
      );

      await expectLater(
        api.login(_provider),
        throwsA(_apiException(ErrorCode.oidcIdentityProviderUnreachable)),
      );
    });

    test('explains an untrusted identity provider certificate', () async {
      final (:api, :paperless, :idp) = _createApi(
        idpHandlers: {
          'GET /.well-known/openid-configuration': (options, _) =>
              throw DioException(
                requestOptions: options,
                type: DioExceptionType.unknown,
                error: const HandshakeException('CERTIFICATE_VERIFY_FAILED'),
              ),
        },
      );

      await expectLater(
        api.login(_provider),
        throwsA(
          _apiException(
            ErrorCode.oidcIdentityProviderUnreachable,
          ).having((e) => e.details, 'details', contains('certificate')),
        ),
      );
    });

    test('reports an HTTP error of the discovery document', () async {
      final (:api, :paperless, :idp) = _createApi(idpHandlers: {});

      await expectLater(
        api.login(_provider),
        throwsA(
          _apiException(
            ErrorCode.oidcLoginFailed,
          ).having((e) => e.httpStatusCode, 'httpStatusCode', 404),
        ),
      );
    });

    test(
      'uses the default scope when the server gives no CSRF cookie',
      () async {
        late Uri authorizationUrl;
        final handlers = _paperlessHandlers(redirectScope: 'openid groups')
          ..['GET /accounts/login/'] = (_, _) =>
              ResponseBody.fromString('<html></html>', 200);
        final (:api, :paperless, :idp) = _createApi(
          paperlessHandlers: handlers,
          browser: _approvingBrowser(onOpen: (url) => authorizationUrl = url),
        );

        await api.login(_provider);

        expect(
          authorizationUrl.queryParameters['scope'],
          'openid profile email',
        );
      },
    );

    test('does not follow redirects while reading the scope', () async {
      final (:api, :paperless, :idp) = _createApi();

      await api.login(_provider);

      final scopeRequests = paperless.requests.where(
        (r) =>
            r.uri.path == '/accounts/login/' ||
            r.uri.path.endsWith('/provider/redirect'),
      );
      expect(scopeRequests, hasLength(2));
      expect(scopeRequests.every((r) => !r.followRedirects), isTrue);
    });

    test('explains that the identity has no Paperless-ngx account', () async {
      final (:api, :paperless, :idp) = _createApi(
        paperlessHandlers: _paperlessHandlers(
          providerToken: (_, _) => _json({
            'status': 401,
            'data': {
              'flows': [
                {'id': 'provider_signup', 'is_pending': true},
              ],
            },
            'meta': {'session_token': 'session-123', 'is_authenticated': false},
          }, 401),
        ),
      );

      await expectLater(
        api.login(_provider),
        throwsA(_apiException(ErrorCode.oidcAccountNotLinked)),
      );
    });

    test('asks for the second factor when the account has one', () async {
      final (:api, :paperless, :idp) = _createApi(
        paperlessHandlers: _paperlessHandlers(
          providerToken: (_, _) => _json({
            'status': 401,
            'data': {
              'flows': [
                {'id': 'mfa_authenticate', 'is_pending': true},
              ],
            },
            'meta': {'session_token': 'session-123', 'is_authenticated': false},
          }, 401),
        ),
      );

      final result = await api.login(_provider);

      expect(result, isA<OidcLoginMfaRequired>());
      expect((result as OidcLoginMfaRequired).sessionToken, 'session-123');
    });

    test('fails when Paperless-ngx rejects the id_token', () async {
      final (:api, :paperless, :idp) = _createApi(
        paperlessHandlers: _paperlessHandlers(
          providerToken: (_, _) => _json({
            'status': 400,
            'errors': [
              {'message': 'Invalid token.', 'code': 'invalid_token'},
            ],
          }, 400),
        ),
      );

      await expectLater(
        api.login(_provider),
        throwsA(
          _apiException(
            ErrorCode.oidcLoginFailed,
          ).having((e) => e.details, 'details', 'Invalid token.'),
        ),
      );
    });
  });

  group('confirmMfa', () {
    _Handler respond(Object data, int status) =>
        (_, _) => _json(data, status);

    Future<String> confirm(_Handler handler) {
      final (:api, :paperless, :idp) = _createApi(
        paperlessHandlers: {
          'POST /api/auth/headless/app/v1/auth/2fa/authenticate': handler,
        },
      );
      return api.confirmMfa(sessionToken: 'session-123', code: '123456');
    }

    test('returns the token and sends the session token', () async {
      late RequestOptions request;
      final token = await confirm((options, _) {
        request = options;
        return _json({
          'status': 200,
          'meta': {'access_token': 'paperless-token'},
        }, 200);
      });

      expect(token, 'paperless-token');
      expect(request.headers['X-Session-Token'], 'session-123');
    });

    test('reports a wrong code', () async {
      await expectLater(
        confirm(
          respond({
            'status': 400,
            'errors': [
              {'code': 'incorrect_code'},
            ],
          }, 400),
        ),
        throwsA(_apiException(ErrorCode.invalidMfaCode)),
      );
    });

    test('reports an expired login', () async {
      await expectLater(
        confirm(respond({'status': 401}, 401)),
        throwsA(_apiException(ErrorCode.oidcSessionExpired)),
      );
    });
  });
}
