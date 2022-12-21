import 'package:json_annotation/json_annotation.dart';
import 'package:paperless_mobile/features/login/model/authentication_information.dart';

part 'authentication_state.g.dart';

@JsonSerializable()
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

  factory AuthenticationState.fromJson(Map<String, dynamic> json) =>
      _$AuthenticationStateFromJson(json);

  Map<String, dynamic> toJson() => _$AuthenticationStateToJson(this);
}
