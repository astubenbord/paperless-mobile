import 'dart:io';

import 'package:paperless_mobile/features/login/model/client_certificate.dart';

extension ClientCertificateHandlingSecurityContext on SecurityContext {
  SecurityContext withClientCertificate(ClientCertificate? clientCertificate) {
    if (clientCertificate == null) return this;
    return this
      ..usePrivateKeyBytes(
        clientCertificate.bytes,
        password: clientCertificate.passphrase,
      )
      ..useCertificateChainBytes(
        clientCertificate.bytes,
        password: clientCertificate.passphrase,
      )
      ..setTrustedCertificatesBytes(
        clientCertificate.bytes,
        password: clientCertificate.passphrase,
      );
  }
}
