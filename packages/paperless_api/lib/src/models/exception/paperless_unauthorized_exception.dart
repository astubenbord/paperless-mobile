class PaperlessUnauthorizedException implements Exception {
  final String? message;

  PaperlessUnauthorizedException(this.message);

  @override
  String toString() =>
      message ?? 'Insufficient permissions to access this resource.';
}
