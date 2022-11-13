class PaperlessServerInformation {
  static const String versionHeader = 'x-version';
  static const String apiVersionHeader = 'x-api-version';
  static const String hostHeader = 'x-served-by';
  final String? version;
  final int? apiVersion;
  final String? username;
  final String? host;
  PaperlessServerInformation({
    this.host,
    this.username,
    this.version = 'unknown',
    this.apiVersion = 1,
  });
}
