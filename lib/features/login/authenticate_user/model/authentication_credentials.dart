import 'package:freezed_annotation/freezed_annotation.dart';

part 'authentication_credentials.g.dart';
part 'authentication_credentials.freezed.dart';

@freezed
sealed class AuthenticationCredentials with _$AuthenticationCredentials {
  const factory AuthenticationCredentials.password({
    required String username,
    required String password,
  }) = PasswordAuthenticationCredentials;

  const factory AuthenticationCredentials.apiKey({required String apiKey}) =
      ApiKeyAuthenticationCredentials;

  /// An OIDC login that is waiting for the second factor of the
  /// Paperless-ngx account. Only used to resume the login from the OTP page.
  const factory AuthenticationCredentials.oidcMfa({
    required String sessionToken,
  }) = OidcMfaAuthenticationCredentials;

  factory AuthenticationCredentials.fromJson(Map<String, Object?> json) =>
      _$AuthenticationCredentialsFromJson(json);
}
