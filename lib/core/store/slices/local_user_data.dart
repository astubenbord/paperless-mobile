// ignore_for_file: invalid_annotation_target

import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:paperless_mobile/core/store/slices/local_user_app_state.dart';
import 'package:paperless_mobile/features/document_scan/model/document_scan.dart';

part 'local_user_data.g.dart';

@CopyWith()
@JsonSerializable()
class LocalUserData {
  final String userId;
  final String serverUrl;
  final String username;
  final String? firstName;
  final String? lastName;
  final bool isBiometricAuthenticationEnabled;
  final LocalUserAppState appState;
  @JsonKey(defaultValue: <DocumentScan>[])
  final List<DocumentScan> documentScans;

  const LocalUserData({
    required this.userId,
    required this.serverUrl,
    required this.username,
    this.firstName,
    this.lastName,
    this.isBiometricAuthenticationEnabled = false,
    this.appState = const LocalUserAppState(),
    this.documentScans = const [],
  });

  Map<String, dynamic> toJson() => _$LocalUserDataToJson(this);
  factory LocalUserData.fromJson(Map<String, dynamic> json) =>
      _$LocalUserDataFromJson(json);

  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else {
      return username;
    }
  }
}
