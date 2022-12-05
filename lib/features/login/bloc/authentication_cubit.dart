import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/store/local_vault.dart';
import 'package:paperless_mobile/di_initializer.dart';
import 'package:paperless_mobile/features/login/model/authentication_information.dart';
import 'package:paperless_mobile/features/login/model/client_certificate.dart';
import 'package:paperless_mobile/features/login/model/user_credentials.model.dart';
import 'package:paperless_mobile/features/login/services/authentication_service.dart';
import 'package:paperless_mobile/features/settings/model/application_settings_state.dart';

@prod
@test
@singleton
class AuthenticationCubit extends Cubit<AuthenticationState> {
  final LocalAuthenticationService _localAuthService;
  final PaperlessAuthenticationApi _authApi;
  final LocalVault _localVault;

  AuthenticationCubit(
    this._localVault,
    this._localAuthService,
    this._authApi,
  ) : super(AuthenticationState.initial);

  Future<void> initialize() {
    return restoreSessionState();
  }

  Future<void> login({
    required UserCredentials credentials,
    required String serverUrl,
    ClientCertificate? clientCertificate,
  }) async {
    assert(credentials.username != null && credentials.password != null);
    try {
      registerSecurityContext(clientCertificate);
      // Store information required to make requests
      final currentAuth = AuthenticationInformation(
        serverUrl: serverUrl,
        clientCertificate: clientCertificate,
      );
      await _localVault.storeAuthenticationInformation(currentAuth);

      final token = await _authApi.login(
        username: credentials.username!,
        password: credentials.password!,
      );

      final auth = currentAuth.copyWith(token: token);

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
      emit(AuthenticationState(isAuthenticated: false, wasLoginStored: false));
    } else {
      if (appSettings.isLocalAuthenticationEnabled) {
        final localAuthSuccess = await _localAuthService
            .authenticateLocalUser("Authenticate to log back in");
        if (localAuthSuccess) {
          registerSecurityContext(storedAuth.clientCertificate);
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
      }
      emit(AuthenticationState(isAuthenticated: false, wasLoginStored: true));
    }
  }

  Future<void> logout() async {
    await _localVault.clear();
    emit(AuthenticationState.initial);
  }
}

class AuthenticationState {
  final bool wasLoginStored;
  final bool? wasLocalAuthenticationSuccessful;
  final bool isAuthenticated;
  final AuthenticationInformation? authentication;

  static final AuthenticationState initial = AuthenticationState(
    wasLoginStored: false,
    isAuthenticated: false,
  );

  AuthenticationState({
    required this.isAuthenticated,
    required this.wasLoginStored,
    this.wasLocalAuthenticationSuccessful,
    this.authentication,
  });

  AuthenticationState copyWith({
    bool? wasLoginStored,
    bool? isAuthenticated,
    AuthenticationInformation? authentication,
    bool? wasLocalAuthenticationSuccessful,
  }) {
    return AuthenticationState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      wasLoginStored: wasLoginStored ?? this.wasLoginStored,
      authentication: authentication ?? this.authentication,
      wasLocalAuthenticationSuccessful: wasLocalAuthenticationSuccessful ??
          this.wasLocalAuthenticationSuccessful,
    );
  }
}
