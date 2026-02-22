import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:paperless_mobile/core/database/hive/hive_config.dart';
import 'package:paperless_mobile/core/database/tables/global_settings.dart';
import 'package:paperless_mobile/core/database/tables/local_user_account.dart';
import 'package:paperless_mobile/core/database/tables/local_user_app_state.dart';

///
/// Opens an encrypted box, calls [callback] with the now opened box, awaits
/// [callback] to return and returns the calculated value. Closes the box after.
///
Future<R?> withEncryptedBox<T, R>(
  String name,
  FutureOr<R?> Function(Box<T> box) callback,
) async {
  final key = await _getEncryptedBoxKey();
  final box = await Hive.openBox<T>(
    name,
    encryptionCipher: HiveAesCipher(key),
  );
  final result = await callback(box);
  await box.close();
  return result;
}

Future<Uint8List> _getEncryptedBoxKey() async {
  const secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
  if (!await secureStorage.containsKey(key: 'key')) {
    final key = Hive.generateSecureKey();

    await secureStorage.write(
      key: 'key',
      value: base64UrlEncode(key),
    );
  }
  final key = (await secureStorage.read(key: 'key'))!;
  return base64Decode(key);
}

extension HiveBoxAccessors on HiveInterface {
  Box<GlobalSettings> get settingsBox =>
      box<GlobalSettings>(HiveBoxes.globalSettings);
  Box<LocalUserAccount> get localUserAccountBox =>
      box<LocalUserAccount>(HiveBoxes.localUserAccount);
  Box<LocalUserAppState> get localUserAppStateBox =>
      box<LocalUserAppState>(HiveBoxes.localUserAppState);
  Box<GlobalSettings> get globalSettingsBox =>
      box<GlobalSettings>(HiveBoxes.globalSettings);
  Box<bool> get hintStateBox => box<bool>(HiveBoxes.hintStateBox);

  /// Returns global settings, falling back to defaults if not yet initialized.
  GlobalSettings get globalSettings =>
      globalSettingsBox.getValue() ?? GlobalSettings(preferredLocaleSubtag: 'en');
}
