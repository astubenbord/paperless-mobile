import 'package:paperless_mobile/core/type/json.dart';
import 'package:paperless_mobile/features/login/model/client_certificate.dart';

class AuthenticationInformation {
  static const usernameKey = 'username';
  static const passwordKey = 'password';
  static const tokenKey = 'token';
  static const serverUrlKey = 'serverUrl';
  static const clientCertificateKey = 'clientCertificate';

  final String username;
  final String password;
  final String token;
  final String serverUrl;
  final ClientCertificate? clientCertificate;

  AuthenticationInformation({
    required this.username,
    required this.password,
    required this.token,
    required this.serverUrl,
    this.clientCertificate,
  });

  AuthenticationInformation.fromJson(JSON json)
      : username = json[usernameKey],
        password = json[passwordKey],
        token = json[tokenKey],
        serverUrl = json[serverUrlKey],
        clientCertificate = json[clientCertificateKey] != null
            ? ClientCertificate.fromJson(json[clientCertificateKey])
            : null;

  JSON toJson() {
    return {
      usernameKey: username,
      passwordKey: password,
      tokenKey: token,
      serverUrlKey: serverUrl,
      clientCertificateKey: clientCertificate?.toJson(),
    };
  }

  bool get isValid {
    return serverUrl.isNotEmpty && token.isNotEmpty;
  }

  AuthenticationInformation copyWith({
    String? username,
    String? password,
    String? token,
    String? serverUrl,
    ClientCertificate? clientCertificate,
    bool removeClientCertificate = false,
    bool? isLocalAuthenticationEnabled,
  }) {
    return AuthenticationInformation(
      username: username ?? this.username,
      password: password ?? this.password,
      token: token ?? this.token,
      serverUrl: serverUrl ?? this.serverUrl,
      clientCertificate:
          clientCertificate ?? (removeClientCertificate ? null : this.clientCertificate),
    );
  }
}
