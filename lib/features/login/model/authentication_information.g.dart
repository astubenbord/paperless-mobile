// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'authentication_information.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthenticationInformation _$AuthenticationInformationFromJson(
        Map<String, dynamic> json) =>
    AuthenticationInformation(
      token: json['token'] as String?,
      serverUrl: json['serverUrl'] as String,
      clientCertificate: json['clientCertificate'] == null
          ? null
          : ClientCertificate.fromJson(
              json['clientCertificate'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AuthenticationInformationToJson(
        AuthenticationInformation instance) =>
    <String, dynamic>{
      'token': instance.token,
      'serverUrl': instance.serverUrl,
      'clientCertificate': instance.clientCertificate,
    };
