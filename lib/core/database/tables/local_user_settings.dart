import 'package:hive_ce/hive.dart';
import 'package:paperless_mobile/core/database/hive/hive_config.dart';

part 'local_user_settings.g.dart';

@HiveType(typeId: HiveTypeIds.localUserSettings)
class LocalUserSettings {
  @HiveField(0)
  bool isBiometricAuthenticationEnabled;

  LocalUserSettings({
    this.isBiometricAuthenticationEnabled = false,
  });
}
