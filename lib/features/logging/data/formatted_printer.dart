import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:paperless_mobile/core/logging/formatted_log_message.dart';

class FormattedPrinter extends LogPrinter {
  static final _timestampFormat = DateFormat("yyyy-MM-dd HH:mm:ss.SSS");
  static const _mulitlineObjectEncoder = JsonEncoder.withIndent(null);

  @override
  List<String> log(LogEvent event) {
    final unformattedMessage = event.message;
    final formattedMessage = switch (unformattedMessage) {
      FormattedLogMessage m => m.format(),
      Iterable i => _mulitlineObjectEncoder
          .convert(i)
          .padLeft(FormattedLogMessage.maxLength),
      Map m => _mulitlineObjectEncoder
          .convert(m)
          .padLeft(FormattedLogMessage.maxLength),
      _ => unformattedMessage.toString().padLeft(FormattedLogMessage.maxLength),
    };
    final formattedLevel = event.level.name
        .toUpperCase()
        .padRight(Level.values.map((e) => e.name.length).max);
    final formattedTimestamp = _timestampFormat.format(event.time);

    return [
      '$formattedTimestamp\t$formattedLevel --- $formattedMessage',
      if (event.error != null) ...[
        "---BEGIN ERROR---",
        event.error.toString(),
        "---END ERROR---",
      ],
      if (event.stackTrace != null) ...[
        "---BEGIN STACKTRACE---",
        event.stackTrace.toString(),
        "---END STACKTRACE---"
      ],
    ];
  }
}
