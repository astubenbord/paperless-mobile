/// Class passed to the printer to be formatted and printed.
class FormattedLogMessage {
  static const maxLength = 55;
  final String message;
  final String methodName;
  final String className;

  FormattedLogMessage(
    this.message, {
    required this.methodName,
    required this.className,
  });

  String format() {
    final formattedClassName = className.padLeft(25);
    final formattedMethodName = methodName.padRight(25);
    return '[$formattedClassName] - $formattedMethodName: $message';
  }
}
