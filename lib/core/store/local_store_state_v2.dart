import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:paperless_mobile/core/store/local_store.dart';
import 'package:paperless_mobile/core/store/slices/global_settings.dart';
import 'package:paperless_mobile/core/store/slices/local_user_app_state.dart';
import 'package:paperless_mobile/core/store/slices/local_user_data.dart';

part 'local_store_state_v2.g.dart';

@Deprecated(
  'Used for migration purposes. Do not use in the app. Use LocalStoreState instead.',
)
@JsonSerializable(createToJson: false)
class _LocalStoreStateV2 {
  const _LocalStoreStateV2({
    this.version = 2,
    this.loggedInAppUserId,
    this.readHints = const [],
    required this.globalSettings,
    this.localUserData = const {},
  });

  final int version;
  final String? loggedInAppUserId;
  final List<String> readHints;
  final GlobalSettings globalSettings;
  final Map<String, _LocalUserDataV2> localUserData;

  factory _LocalStoreStateV2.fromJson(Map<String, dynamic> json) =>
      _$LocalStoreStateV2FromJson(json);
}

@JsonSerializable(createToJson: false)
class _LocalUserDataV2 {
  final String userId;
  final String serverUrl;
  final String username;
  final String? firstName;
  final String? lastName;
  final bool isBiometricAuthenticationEnabled;
  final LocalUserAppState appState;

  const _LocalUserDataV2({
    required this.userId,
    required this.serverUrl,
    required this.username,
    this.firstName,
    this.lastName,
    this.isBiometricAuthenticationEnabled = false,
    this.appState = const LocalUserAppState(),
  });

  factory _LocalUserDataV2.fromJson(Map<String, dynamic> json) =>
      _$LocalUserDataV2FromJson(json);
}

LocalStoreState convertLocalStoreStateV2ToV3(Map<String, dynamic> json) {
  final oldState = _LocalStoreStateV2.fromJson(json);
  return LocalStoreState(
    globalSettings: oldState.globalSettings,
    version: 3,
    loggedInAppUserId: oldState.loggedInAppUserId,
    readHints: oldState.readHints,
    localUserData: {
      for (final entry in oldState.localUserData.entries)
        entry.key: LocalUserData(
          userId: entry.value.userId,
          serverUrl: entry.value.serverUrl,
          username: entry.value.username,
          firstName: entry.value.firstName,
          lastName: entry.value.lastName,
          isBiometricAuthenticationEnabled:
              entry.value.isBiometricAuthenticationEnabled,
          appState: entry.value.appState,
        ),
    },
  );
}
