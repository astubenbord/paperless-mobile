import 'dart:io';

import 'package:paperless_mobile/di_initializer.config.dart';
import 'package:paperless_mobile/di_modules.dart';
import 'package:paperless_mobile/features/login/model/client_certificate.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

final getIt = GetIt.instance..allowReassignment;
@InjectableInit(
  initializerName: r'$initGetIt', // default
  preferRelativeImports: true, // default
  asExtension: false, // default
)
void configureDependencies(String environment) =>
    $initGetIt(getIt, environment: environment);

///
/// Registers new security context, which will be used by the HttpClient, see [RegisterModule].
///
void registerSecurityContext(ClientCertificate? cert) {
  var context = SecurityContext();
  if (cert != null) {
    context = context
      ..usePrivateKeyBytes(cert.bytes, password: cert.passphrase)
      ..useCertificateChainBytes(cert.bytes, password: cert.passphrase)
      ..setTrustedCertificatesBytes(cert.bytes, password: cert.passphrase);
  }
  getIt.unregister<SecurityContext>();
  getIt.registerSingleton<SecurityContext>(context);
}
