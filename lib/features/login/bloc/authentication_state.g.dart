// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'authentication_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthenticationState _$AuthenticationStateFromJson(Map<String, dynamic> json) =>
    AuthenticationState(
      isAuthenticated: json['isAuthenticated'] as bool,
      wasLoginStored: json['wasLoginStored'] as bool,
      wasLocalAuthenticationSuccessful:
          json['wasLocalAuthenticationSuccessful'] as bool?,
      authentication: json['authentication'] == null
          ? null
          : AuthenticationInformation.fromJson(
              json['authentication'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AuthenticationStateToJson(
        AuthenticationState instance) =>
    <String, dynamic>{
      'wasLoginStored': instance.wasLoginStored,
      'wasLocalAuthenticationSuccessful':
          instance.wasLocalAuthenticationSuccessful,
      'isAuthenticated': instance.isAuthenticated,
      'authentication': instance.authentication,
    };
