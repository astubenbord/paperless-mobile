import 'package:bloc/bloc.dart';
import 'package:paperless_mobile/api/paperless_api.dart';
import 'package:paperless_mobile/core/security/session_manager_impl.dart';
import 'package:paperless_mobile/features/login/authenticate_user/model/authentication_credentials.dart';
import 'package:paperless_mobile/features/login/model/client_certificate.dart';
import 'package:paperless_mobile/features/login/server_connection/model/header_entry.dart';

part 'authenticate_user_state.dart';

class AuthenticateUserCubit extends Cubit<AuthenticateUserState> {
  AuthenticateUserCubit() : super(const AuthenticateUserInitial());

  Future<void> login({
    required String serverUrl,
    required AuthenticationCredentials credentials,
    String? otp,
    ClientCertificate? clientCertificate,
    List<HeaderEntry>? additionalHeaders,
  }) async {
    emit(const AuthenticateUserChecking());
    try {
      final sessionManager = SessionManagerImpl()
        ..updateSettings(
          clientCertificate: clientCertificate,
          baseUrl: serverUrl,
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
      emit(AuthenticateUserError(genericError: error));
    }
  }
}
