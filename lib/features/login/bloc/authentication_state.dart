import 'package:json_annotation/json_annotation.dart';
import 'package:paperless_mobile/features/login/model/authentication_information.dart';

part 'authentication_state.g.dart';

@JsonSerializable()
class AuthenticationState {
  final bool wasLoginStored;
  @JsonKey(ignore: true)
  final bool? wasLocalAuthenticationSuccessful;
  final AuthenticationInformation? authentication;

  static final AuthenticationState initial = AuthenticationState(
    wasLoginStored: false,
  );

  bool get isAuthenticated => authentication != null;
  AuthenticationState({
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
