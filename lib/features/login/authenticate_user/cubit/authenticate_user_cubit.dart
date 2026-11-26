import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:paperless_mobile/api/paperless_api.dart';
import 'package:paperless_mobile/core/security/session_manager_impl.dart';
import 'package:paperless_mobile/features/login/authenticate_user/model/authentication_credentials.dart';
import 'package:paperless_mobile/features/login/model/client_certificate.dart';
import 'package:paperless_mobile/features/login/server_connection/model/header_entry.dart';

part 'authenticate_user_state.dart';

class AuthenticateUserCubit extends Cubit<AuthenticateUserState> {
  AuthenticateUserCubit() : super(const AuthenticateUserInitial());

  static SessionManagerImpl _createSession({
    required String serverUrl,
    ClientCertificate? clientCertificate,
    List<HeaderEntry>? additionalHeaders,
  }) {
    return SessionManagerImpl()..updateSettings(
      clientCertificate: clientCertificate,
      baseUrl: serverUrl,
      additionalHeaders: additionalHeaders,
    );
  }

  /// OIDC providers offered by the server for the app login, empty if none.
  static Future<List<OidcProvider>> getOidcProviders({
    required String serverUrl,
    ClientCertificate? clientCertificate,
    List<HeaderEntry>? additionalHeaders,
  }) {
    final session = _createSession(
      serverUrl: serverUrl,
      clientCertificate: clientCertificate,
      additionalHeaders: additionalHeaders,
    );
    return PaperlessOidcApi(session.client).getProviders();
  }

  /// Signs in through [provider] in the system browser. On success the
  /// Paperless-ngx API token goes through the same path as an API key.
  Future<void> loginWithOidc({
    required String serverUrl,
    required OidcProvider provider,
    ClientCertificate? clientCertificate,
    List<HeaderEntry>? additionalHeaders,
  }) async {
    emit(const AuthenticateUserChecking());
    try {
      final session = _createSession(
        serverUrl: serverUrl,
        clientCertificate: clientCertificate,
        additionalHeaders: additionalHeaders,
      );
      final result = await PaperlessOidcApi(session.client).login(provider);
      switch (result) {
        case OidcLoginCancelled():
          emit(const AuthenticateUserInitial());
        case OidcLoginMfaRequired(:final sessionToken):
          emit(
            AuthenticateUserOtpRequired(
              serverUrl: serverUrl,
              credentials: AuthenticationCredentials.oidcMfa(
                sessionToken: sessionToken,
              ),
              clientCertificate: clientCertificate,
              additionalHeaders: additionalHeaders,
            ),
          );
        case OidcLoginSuccess(:final token):
          await login(
            serverUrl: serverUrl,
            credentials: AuthenticationCredentials.apiKey(apiKey: token),
            clientCertificate: clientCertificate,
            additionalHeaders: additionalHeaders,
          );
      }
    } catch (error) {
      final cause = _unwrapDioException(error);
      emit(
        AuthenticateUserError(
          genericError: cause is PaperlessApiException
              ? cause
              : PaperlessApiException(
                  ErrorCode.oidcLoginFailed,
                  details: cause is DioException
                      ? cause.message
                      : cause.toString(),
                ),
        ),
      );
    }
  }

  /// The interceptors of the session client wrap their errors (e.g.
  /// [ErrorCode.deviceOffline]) in a [DioException]: show those instead.
  static Object _unwrapDioException(Object error) {
    if (error is DioException && error.error is PaperlessApiException) {
      return error.error!;
    }
    return error;
  }

  Future<void> login({
    required String serverUrl,
    required AuthenticationCredentials credentials,
    String? otp,
    ClientCertificate? clientCertificate,
    List<HeaderEntry>? additionalHeaders,
  }) async {
    emit(const AuthenticateUserChecking());
    try {
      final sessionManager = _createSession(
        serverUrl: serverUrl,
        clientCertificate: clientCertificate,
        additionalHeaders: additionalHeaders,
      );

      final tempAuthApi = PaperlessAuthenticationApiImpl(sessionManager.client);
      String token;
      int apiVersion;
      switch (credentials) {
        case PasswordAuthenticationCredentials(
          :final username,
          :final password,
        ):
          final response = await tempAuthApi.token(
            PaperlessAuthTokenRequest(
              username: username,
              password: password,
              code: otp,
            ),
          );
          token = response.value;
          apiVersion = response.apiVersion;
          break;
        case ApiKeyAuthenticationCredentials(:final apiKey):
          final response = await tempAuthApi.validateToken(apiKey);
          token = apiKey;
          apiVersion = response.apiVersion;
        case OidcMfaAuthenticationCredentials(:final sessionToken):
          token = await PaperlessOidcApi(
            sessionManager.client,
          ).confirmMfa(sessionToken: sessionToken, code: otp ?? '');
          final response = await tempAuthApi.validateToken(token);
          apiVersion = response.apiVersion;
      }
      emit(
        AuthenticateUserSuccess(
          serverUrl: serverUrl,
          apiVersion: apiVersion,
          token: token,
          clientCertificate: clientCertificate,
          additionalHeaders: additionalHeaders,
        ),
      );
    } on PaperlessApiException catch (error) {
      if (error.code == ErrorCode.mfaCodeRequired) {
        emit(
          AuthenticateUserOtpRequired(
            serverUrl: serverUrl,
            credentials: credentials,
            clientCertificate: clientCertificate,
            additionalHeaders: additionalHeaders,
          ),
        );
      } else {
        emit(AuthenticateUserError(genericError: error));
      }
    } on PaperlessFormValidationException catch (error) {
      if (error.hasUnspecificErrorMessage()) {
        emit(
          AuthenticateUserError(nonFieldError: error.unspecificErrorMessage()),
        );
      } else {
        emit(AuthenticateUserError(fieldErrors: error.validationMessages));
      }
    } catch (error) {
      emit(AuthenticateUserError(genericError: _unwrapDioException(error)));
    }
  }
}
