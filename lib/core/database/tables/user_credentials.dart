import 'package:hive_ce/hive.dart';
import 'package:paperless_mobile/core/database/hive/hive_config.dart';
import 'package:paperless_mobile/core/model/client_certificate.dart';

part 'user_credentials.g.dart';

@HiveType(typeId: HiveTypeIds.localUserCredentials)
class UserCredentials extends HiveObject {
  @HiveField(0)
  final String token;
  @HiveField(1)
  final ClientCertificate? clientCertificate;

  UserCredentials({
    required this.token,
    this.clientCertificate,
  });
}
