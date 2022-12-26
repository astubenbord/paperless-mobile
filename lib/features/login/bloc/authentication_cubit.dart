import 'dart:io';

import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/security/authentication_aware_dio_manager.dart';
import 'package:paperless_mobile/core/store/local_vault.dart';
import 'package:paperless_mobile/features/login/bloc/authentication_state.dart';
import 'package:paperless_mobile/features/login/model/authentication_information.dart';
import 'package:paperless_mobile/features/login/model/client_certificate.dart';
import 'package:paperless_mobile/features/login/model/user_credentials.model.dart';
import 'package:paperless_mobile/features/login/services/authentication_service.dart';
import 'package:paperless_mobile/features/settings/model/application_settings_state.dart';

class AuthenticationCubit extends HydratedCubit<AuthenticationState> {
  final LocalAuthenticationService _localAuthService;
  final PaperlessAuthenticationApi _authApi;
  final LocalVault _localVault;
  final AuthenticationAwareDioManager _dioWrapper;

  AuthenticationCubit(
    this._localVault,
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
    try {
      _dioWrapper.updateSettings(
        baseUrl: serverUrl,
        clientCertificate: clientCertificate,
      );

      final token = await _authApi.login(
        username: credentials.username!,
        password: credentials.password!,
      );

      final auth = AuthenticationInformation(
        serverUrl: serverUrl,
        clientCertificate: clientCertificate,
        token: token,
      );

      await _localVault.storeAuthenticationInformation(auth);

      emit(AuthenticationState(
        isAuthenticated: true,
        wasLoginStored: false,
        authentication: auth,
      ));
    } on TlsException catch (_) {
      const error = PaperlessServerException(
          ErrorCode.invalidClientCertificateConfiguration);
      throw error;
    } on SocketException catch (err) {
      if (err.message.contains("connection timed out")) {
        throw const PaperlessServerException(ErrorCode.requestTimedOut);
      } else {
        throw const PaperlessServerException.unknown();
      }
    }
  }

  Future<void> restoreSessionState() async {
    final storedAuth = await _localVault.loadAuthenticationInformation();
    late ApplicationSettingsState? appSettings;
    try {
      appSettings = await _localVault.loadApplicationSettings() ??
          ApplicationSettingsState.defaultSettings;
    } catch (err) {
      appSettings = ApplicationSettingsState.defaultSettings;
    }
    if (storedAuth == null || !storedAuth.isValid) {
      return emit(
        AuthenticationState(isAuthenticated: false, wasLoginStored: false),
      );
    } else {
      if (appSettings.isLocalAuthenticationEnabled) {
        final localAuthSuccess = await _localAuthService
            .authenticateLocalUser("Authenticate to log back in");
        if (localAuthSuccess) {
          _dioWrapper.updateSettings(
            clientCertificate: storedAuth.clientCertificate,
          );
          return emit(
            AuthenticationState(
              isAuthenticated: true,
              wasLoginStored: true,
              authentication: storedAuth,
              wasLocalAuthenticationSuccessful: true,
            ),
          );
        } else {
          return emit(AuthenticationState(
            isAuthenticated: false,
            wasLoginStored: true,
            wasLocalAuthenticationSuccessful: false,
          ));
        }
      } else {
        _dioWrapper.updateSettings(
          clientCertificate: storedAuth.clientCertificate,
        );
        final authState = AuthenticationState(
          isAuthenticated: true,
          authentication: storedAuth,
          wasLoginStored: true,
        );
        return emit(authState);
      }
    }
  }

  Future<void> logout() async {
    await _localVault.clear();
    await super.clear();
    emit(AuthenticationState.initial);
  }

  @override
  AuthenticationState? fromJson(Map<String, dynamic> json) =>
      AuthenticationState.fromJson(json);

  @override
  Map<String, dynamic>? toJson(AuthenticationState state) => state.toJson();
}
