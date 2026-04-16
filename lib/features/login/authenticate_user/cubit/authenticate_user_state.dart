part of 'authenticate_user_cubit.dart';

sealed class AuthenticateUserState {
  const AuthenticateUserState();
}

class AuthenticateUserInitial extends AuthenticateUserState {
  const AuthenticateUserInitial();
}

class AuthenticateUserChecking extends AuthenticateUserState {
  const AuthenticateUserChecking();
}

class AuthenticateUserOtpRequired extends AuthenticateUserState {
  final String serverUrl;
  final AuthenticationCredentials credentials;
  final ClientCertificate? clientCertificate;
  final List<HeaderEntry>? additionalHeaders;
  const AuthenticateUserOtpRequired({
    required this.serverUrl,
    required this.credentials,
    this.clientCertificate,
    this.additionalHeaders,
  });
}

class AuthenticateUserFieldValidationError extends AuthenticateUserState {
  final Map<String, String> fieldErrors;
  const AuthenticateUserFieldValidationError({required this.fieldErrors});
}

class AuthenticateUserSuccess extends AuthenticateUserState {
  final String serverUrl;
  final String token;
  final int apiVersion;
  final ClientCertificate? clientCertificate;
  final List<HeaderEntry>? additionalHeaders;
  const AuthenticateUserSuccess({
    required this.serverUrl,
    required this.token,
    this.additionalHeaders,
    this.clientCertificate,
    required this.apiVersion,
  });
}

class AuthenticateUserError extends AuthenticateUserState {
  final Map<String, String>? fieldErrors;
  final String? nonFieldError;
  final dynamic genericError;
  const AuthenticateUserError({
    this.fieldErrors,
    this.nonFieldError,
    this.genericError,
  });
}
