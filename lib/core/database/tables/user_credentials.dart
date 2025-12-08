import 'package:hive_ce/hive.dart';
import 'package:paperless_mobile/core/database/hive/hive_config.dart';
import 'package:paperless_mobile/features/login/model/client_certificate.dart';

part 'user_credentials.g.dart';

@HiveType(typeId: HiveTypeIds.localUserCredentials)
class UserCredentials extends HiveObject {
  @HiveField(0)
  final String token;
  @HiveField(1)
  final ClientCertificate? clientCertificate;
  @HiveField(2)
  final Map<String, String> customHeaders;

  UserCredentials({
    required this.token,
    this.clientCertificate,
    this.customHeaders = const {},
  });
}
