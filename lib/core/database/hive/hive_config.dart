import 'package:hive_ce_flutter/adapters.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/database/hive/custom_adapters/theme_mode_adapter.dart';
import 'package:paperless_mobile/core/database/tables/global_settings.dart';
import 'package:paperless_mobile/core/database/tables/local_user_app_state.dart';
import 'package:paperless_mobile/core/database/tables/user_credentials.dart';
import 'package:paperless_mobile/features/login/model/authentication_information.dart';
import 'package:paperless_mobile/core/model/client_certificate.dart';
import 'package:paperless_mobile/core/database/tables/local_user_account.dart';
import 'package:paperless_mobile/core/model/color_scheme_option.dart';
import 'package:paperless_mobile/core/database/tables/local_user_settings.dart';
import 'package:paperless_mobile/core/model/file_download_type.dart';
import 'package:paperless_mobile/core/model/view_type.dart';

class HiveBoxes {
  HiveBoxes._();
  static const globalSettings = 'globalSettings';
  static const localUserCredentials = 'localUserCredentials';
  static const localUserAccount = 'localUserAccount';
  static const localUserAppState = 'localUserAppState';
  static const hosts = 'hosts';
  static const hintStateBox = 'hintStateBox';

  static List<String> get all => [
        globalSettings,
        localUserCredentials,
        localUserAccount,
        localUserAppState,
        hintStateBox,
        hosts,
      ];
}

class HiveTypeIds {
  HiveTypeIds._();
  static const globalSettings = 0;
  static const localUserSettings = 1;
  static const themeMode = 2;
  static const colorSchemeOption = 3;
  static const authentication = 4;
  static const clientCertificate = 5;
  static const localUserCredentials = 6;
  static const localUserAccount = 7;
  static const viewType = 9;
  static const fileDownloadType = 10;
  static const localUserAppState = 8;
}

void registerHiveAdapters() {
  registerPaperlessApiHiveTypeAdapters();
  Hive.registerAdapter(ColorSchemeOptionAdapter());
  Hive.registerAdapter(ThemeModeAdapter());
  Hive.registerAdapter(GlobalSettingsAdapter());
  Hive.registerAdapter(AuthenticationInformationAdapter());
  Hive.registerAdapter(ClientCertificateAdapter());
  Hive.registerAdapter(LocalUserSettingsAdapter());
  Hive.registerAdapter(UserCredentialsAdapter());
  Hive.registerAdapter(LocalUserAccountAdapter());
  Hive.registerAdapter(LocalUserAppStateAdapter());
  Hive.registerAdapter(ViewTypeAdapter());
  Hive.registerAdapter(FileDownloadTypeAdapter());
}

extension HiveSingleValueBox<T> on Box<T> {
  static const _valueKey = 'SINGLE_VALUE';
  bool get hasValue => containsKey(_valueKey);

  T? getValue() => get(_valueKey);

  Future<void> setValue(T value) => put(_valueKey, value);
}
