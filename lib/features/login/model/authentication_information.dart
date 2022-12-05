import 'package:paperless_mobile/core/type/types.dart';
import 'package:paperless_mobile/features/login/model/client_certificate.dart';

class AuthenticationInformation {
  static const tokenKey = 'token';
  static const serverUrlKey = 'serverUrl';
  static const clientCertificateKey = 'clientCertificate';

  final String? token;
  final String serverUrl;
  final ClientCertificate? clientCertificate;

  AuthenticationInformation({
    this.token,
    required this.serverUrl,
    this.clientCertificate,
  });

  AuthenticationInformation.fromJson(JSON json)
      : token = json[tokenKey],
        serverUrl = json[serverUrlKey],
        clientCertificate = json[clientCertificateKey] != null
            ? ClientCertificate.fromJson(json[clientCertificateKey])
            : null;

  JSON toJson() {
    return {
      tokenKey: token,
      serverUrlKey: serverUrl,
      clientCertificateKey: clientCertificate?.toJson(),
    };
  }

  bool get isValid {
    return serverUrl.isNotEmpty && (token?.isNotEmpty ?? false);
  }

  AuthenticationInformation copyWith({
    String? token,
    String? serverUrl,
    ClientCertificate? clientCertificate,
    bool removeClientCertificate = false,
  }) {
    return AuthenticationInformation(
      token: token ?? this.token,
      serverUrl: serverUrl ?? this.serverUrl,
      clientCertificate: clientCertificate ??
          (removeClientCertificate ? null : this.clientCertificate),
    );
  }
}
