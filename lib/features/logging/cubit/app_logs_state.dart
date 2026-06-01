part of 'app_logs_cubit.dart';

sealed class AppLogsState {
  final DateTime date;
  const AppLogsState({required this.date});
}

class AppLogsStateInitial extends AppLogsState {
  const AppLogsStateInitial({required super.date});
}

class AppLogsStateLoading extends AppLogsState {
  const AppLogsStateLoading({required super.date});
}

class AppLogsStateLoaded extends AppLogsState {
  const AppLogsStateLoaded({
    required super.date,
    required this.logs,
    required this.availableLogs,
  });
  final List<DateTime> availableLogs;
  final List<ParsedLogMessage> logs;
}

class AppLogsStateError extends AppLogsState {
  const AppLogsStateError({required this.error, required super.date});

  final Object error;
}
