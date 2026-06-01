part of 'local_store.dart';

@CopyWith()
@JsonSerializable()
class LocalStoreState {
  const LocalStoreState({
    this.version = 3,
    this.loggedInAppUserId,
    this.readHints = const [],
    required this.globalSettings,
    this.localUserData = const {},
  });
  final int version;
  final String? loggedInAppUserId;
  final List<String> readHints;
  final GlobalSettings globalSettings;
  final Map<String, LocalUserData> localUserData;

  Map<String, dynamic> toJson() => _$LocalStoreStateToJson(this);

  factory LocalStoreState.fromJson(Map<String, dynamic> json) {
    final version = json['version'] as int? ?? 1;
    switch (version) {
      case 1:
        return convertLocalStoreStateV2ToV3(
          convertLocalStoreStateV1ToV2(json).toJson(),
        );
      case 2:
        return convertLocalStoreStateV2ToV3(json);
      case 3:
        return _$LocalStoreStateFromJson(json);
      default:
        throw Exception('Unsupported local store state version: $version');
    }
  }
}
