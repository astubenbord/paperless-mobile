// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'authentication_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthenticationState _$AuthenticationStateFromJson(Map<String, dynamic> json) =>
    AuthenticationState(
      wasLoginStored: json['wasLoginStored'] as bool,
      authentication: json['authentication'] == null
          ? null
          : AuthenticationInformation.fromJson(
              json['authentication'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AuthenticationStateToJson(
        AuthenticationState instance) =>
    <String, dynamic>{
      'wasLoginStored': instance.wasLoginStored,
      'authentication': instance.authentication,
    };
