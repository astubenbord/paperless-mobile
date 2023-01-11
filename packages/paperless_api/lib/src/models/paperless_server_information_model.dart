import 'package:paperless_api/src/request_utils.dart';

class PaperlessServerInformationModel {
  static const String versionHeader = 'x-version';
  static const String apiVersionHeader = 'x-api-version';
  static const String hostHeader = 'x-served-by';
  final String? version;
  final int? apiVersion;
  final String? username;
  final String? host;

  PaperlessServerInformationModel({
    this.host,
    this.username,
    this.version = 'unknown',
    this.apiVersion = 1,
  });

  int compareToOtherVersion(String? other) {
    return getExtendedVersionNumber(version ?? '0.0.0')
        .compareTo(getExtendedVersionNumber(other ?? '0.0.0'));
  }
}
