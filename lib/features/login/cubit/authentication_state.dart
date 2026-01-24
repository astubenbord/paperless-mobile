part of 'authentication_cubit.dart';

sealed class AuthenticationState {
  const AuthenticationState();

  bool get isAuthenticated =>
      switch (this) { AuthenticatedState() => true, _ => false };
}

class UnauthenticatedState extends AuthenticationState with EquatableMixin {
  final bool redirectToAccountSelection;

  const UnauthenticatedState({this.redirectToAccountSelection = false});

  @override
  List<Object?> get props => [redirectToAccountSelection];
}

class RestoringSessionState extends AuthenticationState {
  const RestoringSessionState();
}

class VerifyIdentityState extends AuthenticationState {
  final String userId;
  const VerifyIdentityState({required this.userId});
}

class AuthenticatingState extends AuthenticationState with EquatableMixin {
  final AuthenticatingStage currentStage;
  const AuthenticatingState(this.currentStage);

  @override
  List<Object?> get props => [currentStage];
}

class LoggingOutState extends AuthenticationState {
  const LoggingOutState();
}

class AuthenticatedState extends AuthenticationState with EquatableMixin {
  final String localUserId;

  const AuthenticatedState({required this.localUserId});

  @override
  List<Object?> get props => [localUserId];
}

class SwitchingAccountsState extends AuthenticationState {
  const SwitchingAccountsState();
}

class ClientCertificateRequiredState extends AuthenticationState
    with EquatableMixin {
  final String serverUrl;
  final String username;
  // Password is kept in state for retry logic but NOT in props
  // to avoid it appearing in debug logs or equality comparisons
  final String password;

  const ClientCertificateRequiredState({
    required this.serverUrl,
    required this.username,
    required this.password,
  });

  @override
  // Deliberately exclude password from equality comparison for security
  List<Object?> get props => [serverUrl, username];
}

class AuthenticationErrorState extends AuthenticationState with EquatableMixin {
  final ErrorCode? errorCode;
  final String serverUrl;
  final ClientCertificate? clientCertificate;
  final String username;
  final String password;

  const AuthenticationErrorState({
    this.errorCode,
    required this.serverUrl,
    this.clientCertificate,
    required this.username,
    required this.password,
  });

  @override
  List<Object?> get props => [
        errorCode,
        serverUrl,
        clientCertificate,
        username,
        password,
      ];
}

enum AuthenticatingStage {
  authenticating,
  persistingLocalUserData,
  fetchingUserInformation,
}
