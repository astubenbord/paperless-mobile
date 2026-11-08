import 'dart:io';
import 'package:logger/logger.dart';

final _newLine = Platform.lineTerminator;

sealed class ParsedLogMessage {
  static List<ParsedLogMessage> parse(List<String> logs) {
    List<ParsedLogMessage> messages = [];
    int offset = 0;
    while (offset < logs.length) {
      final currentLine = logs[offset];
      if (ParsedFormattedLogMessage.canConsumeFirstLine(currentLine)) {
        final (consumedLines, result) = ParsedFormattedLogMessage.consume(
          logs.sublist(offset),
        );
        messages.add(result);
        offset += consumedLines;
      } else {
        messages.add(UnformattedLogMessage(currentLine));
        offset++;
      }
    }
    return messages;
  }
}

class ParsedErrorLogMessage {
  static final RegExp _errorBeginPattern = RegExp(r"---BEGIN ERROR---\s*");
  static final RegExp _errorEndPattern = RegExp(r"---END ERROR---\s*");
  static final RegExp _stackTraceBeginPattern = RegExp(
    r"---BEGIN STACKTRACE---\s*",
  );
  static final RegExp _stackTraceEndPattern = RegExp(
    r"---END STACKTRACE---\s*",
  );
  final String error;
  final String? stackTrace;
  ParsedErrorLogMessage({required this.error, this.stackTrace});
  static bool canConsumeFirstLine(String line) =>
      _errorBeginPattern.hasMatch(line);

  static (int consumedLines, ParsedErrorLogMessage? result) consume(
    List<String> log,
  ) {
    assert(log.isNotEmpty && canConsumeFirstLine(log.first));
    String errorText = "";
    int currentLine =
        1; // Skip first because we know that the first line is ---BEGIN ERROR---

    while (!_errorEndPattern.hasMatch(log[currentLine])) {
      errorText += log[currentLine] + _newLine;
      currentLine++;
    }
    currentLine++;
    if (log.length == currentLine) {
      return (currentLine, ParsedErrorLogMessage(error: errorText));
    }
    final hasStackTrace = _stackTraceBeginPattern.hasMatch(log[currentLine]);
    String? stackTrace;
    if (hasStackTrace) {
      currentLine++;
      String stackTraceText = '';

      while (!_stackTraceEndPattern.hasMatch(log[currentLine])) {
        stackTraceText += log[currentLine] + _newLine;
        currentLine++;
      }
      stackTrace = stackTraceText;
    }
    return (
      currentLine + 1,
      ParsedErrorLogMessage(error: errorText, stackTrace: stackTrace),
    );
  }
}

class UnformattedLogMessage extends ParsedLogMessage {
  final String message;

  UnformattedLogMessage(this.message);
}

class ParsedFormattedLogMessage extends ParsedLogMessage {
  static final RegExp pattern = RegExp(
    r'(?<timestamp>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})\s*(?<level>[A-Z]*)'
    r'\s*---\s*(?:\[\s*(?<className>.*)\]\s*-\s*(?<methodName>.*)\s*)?:\s*(?<message>.+)',
  );

  final Level level;
  final String message;
  final String? className;
  final String? methodName;
  final DateTime timestamp;

  final ParsedErrorLogMessage? error;

  ParsedFormattedLogMessage({
    required this.level,
    required this.message,
    this.className,
    this.methodName,
    required this.timestamp,
    this.error,
  });

  static bool canConsumeFirstLine(String line) => pattern.hasMatch(line);

  static (int consumedLines, ParsedFormattedLogMessage result) consume(
    List<String> log,
  ) {
    assert(log.isNotEmpty && canConsumeFirstLine(log.first));

    final match = pattern.firstMatch(log.first)!;
    final result = ParsedFormattedLogMessage(
      level: Level.values.byName(match.namedGroup('level')!.toLowerCase()),
      message: match.namedGroup('message')!,
      className: match.namedGroup('className'),
      methodName: match.namedGroup('methodName'),
      timestamp: DateTime.parse(match.namedGroup('timestamp')!),
    );
    final updatedLog = log.sublist(1);
    if (updatedLog.isEmpty) {
      return (1, result);
    }
    if (ParsedErrorLogMessage.canConsumeFirstLine(updatedLog.first)) {
      final (consumedLines, parsedError) = ParsedErrorLogMessage.consume(
        updatedLog,
      );
      return (consumedLines + 1, result.copyWith(error: parsedError));
    }
    return (1, result);
  }

  ParsedFormattedLogMessage copyWith({
    Level? level,
    String? message,
    String? className,
    String? methodName,
    DateTime? timestamp,
    ParsedErrorLogMessage? error,
  }) {
    return ParsedFormattedLogMessage(
      level: level ?? this.level,
      message: message ?? this.message,
      className: className ?? this.className,
      methodName: methodName ?? this.methodName,
      timestamp: timestamp ?? this.timestamp,
      error: error ?? this.error,
    );
  }
}
