import 'package:logger/logger.dart';
import 'package:paperless_mobile/core/logging/formatted_log_message.dart';

late Logger logger;

extension FormattedLoggerExtension on Logger {
  void ft(
    dynamic message, {
    String className = '',
    String methodName = '',
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final formattedMessage = FormattedLogMessage(
      message,
      className: className,
      methodName: methodName,
    );
    log(
      Level.trace,
      formattedMessage,
      time: time,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void fw(
    dynamic message, {
    String className = '',
    String methodName = '',
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final formattedMessage = FormattedLogMessage(
      message,
      className: className,
      methodName: methodName,
    );
    log(
      Level.warning,
      formattedMessage,
      time: time,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void fd(
    dynamic message, {
    String className = '',
    String methodName = '',
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final formattedMessage = FormattedLogMessage(
      message,
      className: className,
      methodName: methodName,
    );
    log(
      Level.debug,
      formattedMessage,
      time: time,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void fi(
    dynamic message, {
    String className = '',
    String methodName = '',
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final formattedMessage = FormattedLogMessage(
      message,
      className: className,
      methodName: methodName,
    );
    log(
      Level.info,
      formattedMessage,
      time: time,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void fe(
    dynamic message, {
    String className = '',
    String methodName = '',
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final formattedMessage = FormattedLogMessage(
      message,
      className: className,
      methodName: methodName,
    );
    log(
      Level.error,
      formattedMessage,
      time: time,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
