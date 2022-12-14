import 'dart:io';

import 'package:paperless_mobile/di_initializer.config.dart';
import 'package:paperless_mobile/di_modules.dart';
import 'package:paperless_mobile/features/login/model/client_certificate.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

final getIt = GetIt.instance..allowReassignment;

@InjectableInit(
  initializerName: 'init', // default
  preferRelativeImports: true, // default
  asExtension: false, // default
  includeMicroPackages: false,
)
void configureDependencies(String environment) =>
    init(getIt, environment: environment);

///
/// Registers new security context, which will be used by the HttpClient, see [RegisterModule].
///
Future<void> registerSecurityContext(ClientCertificate? cert) async {
  var context = SecurityContext();
  if (cert != null) {
    context = context
      ..usePrivateKeyBytes(cert.bytes, password: cert.passphrase)
      ..useCertificateChainBytes(cert.bytes, password: cert.passphrase)
      ..setTrustedCertificatesBytes(cert.bytes, password: cert.passphrase);
  }
  await getIt.unregister<SecurityContext>();
  getIt.registerSingleton<SecurityContext>(context);
}
