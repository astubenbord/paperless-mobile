import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:paperless_mobile/api/paperless_api.dart';

/// An OIDC provider configured on the Paperless-ngx server (django-allauth
/// social account) that supports the headless app login flow.
class OidcProvider {
  final String id;
  final String name;
  final String clientId;
  final String openidConfigurationUrl;

  const OidcProvider({
    required this.id,
    required this.name,
    required this.clientId,
    required this.openidConfigurationUrl,
  });
}

sealed class OidcLoginResult {
  const OidcLoginResult();
}

class OidcLoginSuccess extends OidcLoginResult {
  final String token;
  const OidcLoginSuccess(this.token);
}

/// The Paperless-ngx account has a second factor (TOTP): the code has to be
/// confirmed with [PaperlessOidcApi.confirmMfa] using [sessionToken].
class OidcLoginMfaRequired extends OidcLoginResult {
  final String sessionToken;
  const OidcLoginMfaRequired(this.sessionToken);
}

class OidcLoginCancelled extends OidcLoginResult {
  const OidcLoginCancelled();
}

/// Opens [url] in the system browser and returns the callback URL once the
/// identity provider redirects to [callbackUrlScheme].
typedef BrowserAuthenticator =
    Future<String> Function({
      required String url,
      required String callbackUrlScheme,
    });

Future<String> _authenticateInSystemBrowser({
  required String url,
  required String callbackUrlScheme,
}) {
  return FlutterWebAuth2.authenticate(
    url: url,
    callbackUrlScheme: callbackUrlScheme,
  );
}

/// OIDC login through the django-allauth headless API of Paperless-ngx
/// (`api/auth/headless/`, paperless-ngx/paperless-ngx#11756).
///
/// The app authenticates the user directly with the identity provider in the
/// system browser (authorization code flow with PKCE, as a public client),
/// then hands the resulting `id_token` to Paperless-ngx, which returns a
/// regular API token. The identity provider must therefore accept the
/// Paperless client as a public client and list [callbackUrl] among its
/// redirect URIs.
class PaperlessOidcApi {
  static const callbackScheme = 'x-paperless';
  static const callbackUrl = '$callbackScheme://oidc-callback';
  static const _headlessPath = '/api/auth/headless';
  static const _defaultScope = 'openid profile email';

  /// Client for the Paperless-ngx server: carries base URL, client
  /// certificate and additional headers.
  final Dio paperlessClient;

  /// Separate client for the identity provider, so that the additional
  /// headers and the client certificate configured for Paperless-ngx never
  /// reach another origin. Unlike the Paperless-ngx client, it validates TLS
  /// certificates.
  final Dio identityProviderClient;

  final BrowserAuthenticator _authenticate;

  PaperlessOidcApi(
    this.paperlessClient, {
    Dio? identityProviderClient,
    BrowserAuthenticator authenticate = _authenticateInSystemBrowser,
  }) : identityProviderClient =
           identityProviderClient ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 10),
               receiveTimeout: const Duration(seconds: 30),
               sendTimeout: const Duration(seconds: 10),
             ),
           ),
       _authenticate = authenticate;

  /// Returns the providers that support the app login flow, or an empty list
  /// if the server does not offer it (older versions, no social accounts).
  Future<List<OidcProvider>> getProviders() async {
    try {
      final response = await paperlessClient.get(
        '$_headlessPath/app/v1/config',
        // Older servers answer 404: not an error, just no providers.
        options: Options(validateStatus: (_) => true),
      );
      if (response.statusCode != HttpStatus.ok || response.data is! Map) {
        return [];
      }
      final providers =
          response.data['data']?['socialaccount']?['providers'] as List? ?? [];
      return [
        for (final provider in providers.whereType<Map>())
          if (provider['flows'] case final List flows
              when flows.contains('provider_token') &&
                  flows.contains('provider_redirect'))
            if (provider['id'] is String &&
                provider['client_id'] is String &&
                provider['openid_configuration_url'] is String)
              OidcProvider(
                id: provider['id'] as String,
                name: provider['name'] as String? ?? provider['id'] as String,
                clientId: provider['client_id'] as String,
                openidConfigurationUrl:
                    provider['openid_configuration_url'] as String,
              ),
      ];
    } catch (_) {
      return [];
    }
  }

  Future<OidcLoginResult> login(OidcProvider provider) async {
    final discovery = await _getDiscovery(provider.openidConfigurationUrl);
    final authorizationEndpoint = discovery['authorization_endpoint'];
    final tokenEndpoint = discovery['token_endpoint'];
    if (authorizationEndpoint is! String || tokenEndpoint is! String) {
      throw const PaperlessApiException(
        ErrorCode.oidcLoginFailed,
        details: 'Incomplete OpenID configuration of the identity provider.',
      );
    }

    final scope = await _getScope(provider);
    final verifier = _randomString(64);
    final challenge = base64UrlEncode(
      sha256.convert(ascii.encode(verifier)).bytes,
    ).replaceAll('=', '');
    final state = _randomString(32);

    final authorizationUri = Uri.parse(authorizationEndpoint);
    final authorizationUrl = authorizationUri.replace(
      queryParameters: {
        ...authorizationUri.queryParameters,
        'client_id': provider.clientId,
        'redirect_uri': callbackUrl,
        'response_type': 'code',
        'scope': scope,
        'state': state,
        'code_challenge': challenge,
        'code_challenge_method': 'S256',
      },
    );

    final String callback;
    try {
      callback = await _authenticate(
        url: authorizationUrl.toString(),
        callbackUrlScheme: callbackScheme,
      );
    } on PlatformException catch (error) {
      if (error.code == 'CANCELED') {
        return const OidcLoginCancelled();
      }
      rethrow;
    }

    final params = Uri.parse(callback).queryParameters;
    if (params['error'] == 'access_denied') {
      return const OidcLoginCancelled();
    }
    if (params['error'] != null) {
      throw _identityProviderError(params);
    }
    final code = params['code'];
    if (params['state'] != state || code == null) {
      throw const PaperlessApiException(
        ErrorCode.oidcLoginFailed,
        details: 'Invalid response from the identity provider.',
      );
    }

    final idToken = await _exchangeCode(
      tokenEndpoint: tokenEndpoint,
      clientId: provider.clientId,
      code: code,
      verifier: verifier,
    );
    return _exchangeIdToken(provider, idToken);
  }

  /// Confirms the second factor of a login suspended with
  /// [OidcLoginMfaRequired] and returns the Paperless-ngx API token.
  Future<String> confirmMfa({
    required String sessionToken,
    required String code,
  }) async {
    final response = await paperlessClient.post(
      '$_headlessPath/app/v1/auth/2fa/authenticate',
      data: {'code': code},
      options: Options(
        headers: {'X-Session-Token': sessionToken},
        validateStatus: (_) => true,
      ),
    );
    final token = _accessToken(response);
    if (response.statusCode == HttpStatus.ok && token != null) {
      return token;
    }
    switch (response.statusCode) {
      case HttpStatus.badRequest:
        throw const PaperlessApiException(ErrorCode.invalidMfaCode);
      // The pending login is gone: expired, or already completed.
      case HttpStatus.unauthorized || HttpStatus.conflict || HttpStatus.gone:
        throw PaperlessApiException(
          ErrorCode.oidcSessionExpired,
          httpStatusCode: response.statusCode,
        );
      default:
        throw PaperlessApiException(
          ErrorCode.oidcLoginFailed,
          httpStatusCode: response.statusCode,
          details: _paperlessErrorMessage(response),
        );
    }
  }

  Future<Map> _getDiscovery(String url) async {
    try {
      final response = await identityProviderClient.get(url);
      final data = response.data;
      final discovery = data is String ? jsonDecode(data) : data;
      if (discovery is! Map) {
        throw const FormatException('Not a JSON object');
      }
      return discovery;
    } on DioException catch (error) {
      throw _unreachable(error);
    } on FormatException {
      throw const PaperlessApiException(
        ErrorCode.oidcLoginFailed,
        details: 'Invalid OpenID configuration of the identity provider.',
      );
    }
  }

  Future<String> _exchangeCode({
    required String tokenEndpoint,
    required String clientId,
    required String code,
    required String verifier,
  }) async {
    final Response response;
    try {
      response = await identityProviderClient.post(
        tokenEndpoint,
        data: {
          'grant_type': 'authorization_code',
          'client_id': clientId,
          'code': code,
          'redirect_uri': callbackUrl,
          'code_verifier': verifier,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          validateStatus: (_) => true,
        ),
      );
    } on DioException catch (error) {
      throw _unreachable(error);
    }
    final data = response.data is String
        ? _tryJsonDecode(response.data as String)
        : response.data;
    final idToken = data is Map ? data['id_token'] : null;
    if (response.statusCode == HttpStatus.ok && idToken is String) {
      return idToken;
    }
    // Only the OAuth error fields: the body may contain other tokens.
    throw _identityProviderError(
      data is Map ? data : const {},
      httpStatusCode: response.statusCode,
    );
  }

  Future<OidcLoginResult> _exchangeIdToken(
    OidcProvider provider,
    String idToken,
  ) async {
    final response = await paperlessClient.post(
      '$_headlessPath/app/v1/auth/provider/token',
      data: {
        'provider': provider.id,
        'process': 'login',
        'token': {'client_id': provider.clientId, 'id_token': idToken},
      },
      options: Options(validateStatus: (_) => true),
    );
    final token = _accessToken(response);
    if (response.statusCode == HttpStatus.ok && token != null) {
      return OidcLoginSuccess(token);
    }
    if (response.statusCode == HttpStatus.unauthorized &&
        response.data is Map) {
      final flows = response.data['data']?['flows'] as List? ?? [];
      final mfaPending = flows.any(
        (flow) =>
            flow is Map &&
            flow['id'] == 'mfa_authenticate' &&
            flow['is_pending'] == true,
      );
      final sessionToken = response.data['meta']?['session_token'];
      if (mfaPending && sessionToken is String) {
        return OidcLoginMfaRequired(sessionToken);
      }
      // The identity is valid, but Paperless-ngx would have to create an
      // account for it (signup disabled or email to verify).
      final signupPending = flows.any(
        (flow) =>
            flow is Map &&
            (flow['id'] == 'provider_signup' || flow['id'] == 'verify_email') &&
            flow['is_pending'] == true,
      );
      if (signupPending) {
        throw const PaperlessApiException(
          ErrorCode.oidcAccountNotLinked,
          httpStatusCode: HttpStatus.unauthorized,
        );
      }
    }
    throw PaperlessApiException(
      ErrorCode.oidcLoginFailed,
      httpStatusCode: response.statusCode,
      details: _paperlessErrorMessage(response),
    );
  }

  /// The scope Paperless-ngx itself requests from the provider (it may be
  /// configured with more than the default, e.g. for group sync). Read from
  /// the redirect of the browser flow; falls back to the allauth default.
  Future<String> _getScope(OidcProvider provider) async {
    try {
      final loginPage = await paperlessClient.get(
        '/accounts/login/',
        // A redirect (e.g. REDIRECT_LOGIN_TO_SSO) could lead to another
        // origin with the Paperless-ngx headers and client certificate.
        options: Options(followRedirects: false, validateStatus: (_) => true),
      );
      final csrfCookie = loginPage.headers[HttpHeaders.setCookieHeader]
          ?.map(Cookie.fromSetCookieValue)
          .where((cookie) => cookie.name == 'csrftoken')
          .firstOrNull;
      if (csrfCookie == null) {
        return _defaultScope;
      }
      final baseUrl = paperlessClient.options.baseUrl.replaceFirst(
        RegExp(r'/+$'),
        '',
      );
      final response = await paperlessClient.post(
        '$_headlessPath/browser/v1/auth/provider/redirect',
        data: {
          'provider': provider.id,
          'callback_url': '$baseUrl/',
          'process': 'login',
          'csrfmiddlewaretoken': csrfCookie.value,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          followRedirects: false,
          validateStatus: (_) => true,
          headers: {
            HttpHeaders.cookieHeader: 'csrftoken=${csrfCookie.value}',
            'X-CSRFToken': csrfCookie.value,
            HttpHeaders.refererHeader: '$baseUrl/',
          },
        ),
      );
      final location = response.headers.value(HttpHeaders.locationHeader);
      final scope = location == null
          ? null
          : Uri.tryParse(location)?.queryParameters['scope'];
      return scope ?? _defaultScope;
    } catch (_) {
      return _defaultScope;
    }
  }

  /// Maps an OAuth 2.0 error response (RFC 6749, section 5.2) to an
  /// exception. Only `error` and `error_description` are kept.
  static PaperlessApiException _identityProviderError(
    Map params, {
    int? httpStatusCode,
  }) {
    final error = params['error'];
    final description = params['error_description'];
    final details =
        [error, description].whereType<String>().join(': ').ifEmpty ??
        'Unexpected response from the identity provider.';
    // The client is confidential (needs a secret) or does not allow this
    // app's flow: the user has to change the provider configuration.
    final misconfigured =
        error == 'invalid_client' ||
        error == 'unauthorized_client' ||
        (error == 'invalid_request' &&
            description is String &&
            description.toLowerCase().contains('secret'));
    return PaperlessApiException(
      misconfigured ? ErrorCode.oidcClientNotPublic : ErrorCode.oidcLoginFailed,
      httpStatusCode: httpStatusCode,
      details: details,
    );
  }

  static PaperlessApiException _unreachable(DioException error) {
    if (error.type == DioExceptionType.badResponse) {
      return PaperlessApiException(
        ErrorCode.oidcLoginFailed,
        httpStatusCode: error.response?.statusCode,
        details:
            'Identity provider returned HTTP ${error.response?.statusCode}.',
      );
    }
    final cause = error.error;
    return PaperlessApiException(
      ErrorCode.oidcIdentityProviderUnreachable,
      details: cause is HandshakeException
          ? 'TLS handshake with the identity provider failed: '
                'its certificate is not trusted by this device.'
          : error.message,
    );
  }

  /// The messages of an allauth headless error response, without the rest
  /// of the body.
  static String? _paperlessErrorMessage(Response response) {
    final errors = response.data is Map ? response.data['errors'] : null;
    if (errors is! List) {
      return null;
    }
    return errors
        .whereType<Map>()
        .map((error) => error['message'])
        .whereType<String>()
        .join('\n')
        .ifEmpty;
  }

  static String? _accessToken(Response response) {
    final data = response.data;
    if (data is! Map) {
      return null;
    }
    final token = data['meta']?['access_token'];
    return token is String ? token : null;
  }

  static Object? _tryJsonDecode(String source) {
    try {
      return jsonDecode(source);
    } on FormatException {
      return null;
    }
  }

  static String _randomString(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }
}

extension on String {
  String? get ifEmpty => isEmpty ? null : this;
}
