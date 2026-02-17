import 'package:hive_ce/hive.dart';
import 'package:paperless_mobile/core/database/hive/hive_config.dart';
import 'package:paperless_mobile/core/model/client_certificate.dart';

part 'authentication_information.g.dart';

@HiveType(typeId: HiveTypeIds.authentication)
class AuthenticationInformation {
  @HiveField(0)
  String? token;

  @HiveField(1)
  String serverUrl;

  @HiveField(2)
  ClientCertificate? clientCertificate;

  @HiveField(3)
  String username;

  AuthenticationInformation({
    required this.username,
    required this.serverUrl,
    this.token,
    this.clientCertificate,
  });

  bool get isValid {
    return serverUrl.isNotEmpty && (token?.isNotEmpty ?? false);
  }
}
