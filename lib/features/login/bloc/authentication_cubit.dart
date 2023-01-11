import 'package:dio/dio.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/security/session_manager.dart';
import 'package:paperless_mobile/features/login/bloc/authentication_state.dart';
import 'package:paperless_mobile/features/login/model/authentication_information.dart';
import 'package:paperless_mobile/features/login/model/client_certificate.dart';
import 'package:paperless_mobile/features/login/model/user_credentials.model.dart';
import 'package:paperless_mobile/features/login/services/authentication_service.dart';

class AuthenticationCubit extends Cubit<AuthenticationState>
    with HydratedMixin<AuthenticationState> {
  final LocalAuthenticationService _localAuthService;
  final PaperlessAuthenticationApi _authApi;
  final SessionManager _dioWrapper;

  AuthenticationCubit(
    this._localAuthService,
    this._authApi,
    this._dioWrapper,
  ) : super(AuthenticationState.initial);

  Future<void> login({
    required UserCredentials credentials,
    required String serverUrl,
    ClientCertificate? clientCertificate,
  }) async {
    assert(credentials.username != null && credentials.password != null);

    _dioWrapper.updateSettings(
      baseUrl: serverUrl,
      clientCertificate: clientCertificate,
    );
    final token = await _authApi.login(
      username: credentials.username!,
      password: credentials.password!,
    );
    _dioWrapper.updateSettings(
      baseUrl: serverUrl,
      clientCertificate: clientCertificate,
      authToken: token,
    );

    emit(
      AuthenticationState(
        wasLoginStored: false,
        authentication: AuthenticationInformation(
          serverUrl: serverUrl,
          clientCertificate: clientCertificate,
          token: token,
        ),
      ),
    );
  }

  ///
  /// Performs a conditional hydration based on the local authentication success.
  ///
  Future<void> restoreSessionState(bool promptForLocalAuthentication) async {
    final json = HydratedBloc.storage.read(storageToken);

    if (json == null) {
      // If there is nothing to restore, we can quit here.
      return;
    }

    if (promptForLocalAuthentication) {
      final localAuthSuccess = await _localAuthService
          .authenticateLocalUser("Authenticate to log back in");
      if (localAuthSuccess) {
        hydrate();
        if (state.isAuthenticated) {
          _dioWrapper.updateSettings(
            clientCertificate: state.authentication!.clientCertificate,
            authToken: state.authentication!.token,
            baseUrl: state.authentication!.serverUrl,
          );
          return emit(
            AuthenticationState(
              wasLoginStored: true,
              authentication: state.authentication,
              wasLocalAuthenticationSuccessful: true,
            ),
          );
        }
      } else {
        hydrate();
        return emit(
          AuthenticationState(
            wasLoginStored: true,
            wasLocalAuthenticationSuccessful: false,
            authentication: state.authentication,
          ),
        );
      }
    } else {
      hydrate();
      if (state.isAuthenticated) {
        _dioWrapper.updateSettings(
          clientCertificate: state.authentication!.clientCertificate,
          authToken: state.authentication!.token,
          baseUrl: state.authentication!.serverUrl,
        );
        final authState = AuthenticationState(
          authentication: state.authentication!,
          wasLoginStored: true,
        );
        return emit(authState);
      } else {
        return emit(AuthenticationState.initial);
      }
    }
  }

  Future<void> logout() async {
    await clear();
    _dioWrapper.resetSettings();
    emit(AuthenticationState.initial);
  }

  @override
  AuthenticationState? fromJson(Map<String, dynamic> json) =>
      AuthenticationState.fromJson(json);

  @override
  Map<String, dynamic>? toJson(AuthenticationState state) => state.toJson();
}
