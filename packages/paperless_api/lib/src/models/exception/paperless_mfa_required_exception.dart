/// Exception thrown when the server requires a TOTP/MFA code to complete
/// authentication.
class PaperlessMfaRequiredException implements Exception {
  final String message;

  PaperlessMfaRequiredException([this.message = 'MFA code is required']);

  @override
  String toString() => 'PaperlessMfaRequiredException: $message';
}
