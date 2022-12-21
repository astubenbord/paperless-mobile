import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/logic/error_code_localization_mapper.dart';
import 'package:paperless_mobile/core/service/github_issue_service.dart';
import 'package:paperless_mobile/generated/l10n.dart';

final dateFormat = DateFormat("yyyy-MM-dd");
final GlobalKey<ScaffoldState> rootScaffoldKey = GlobalKey<ScaffoldState>();

class SnackBarActionConfig {
  final String label;
  final VoidCallback onPressed;

  SnackBarActionConfig({
    required this.label,
    required this.onPressed,
  });
}

void showSnackBar(
  BuildContext context,
  String message, {
  String? details,
  SnackBarActionConfig? action,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          message + (details != null ? ' ($details)' : ''),
        ),
        action: action != null
            ? SnackBarAction(
                label: action.label,
                onPressed: action.onPressed,
                textColor: Theme.of(context).colorScheme.onInverseSurface,
              )
            : null,
        duration: const Duration(seconds: 5),
      ),
    );
}

void showGenericError(
  BuildContext context,
  dynamic error, [
  StackTrace? stackTrace,
]) {
  showSnackBar(
    context,
    error.toString(),
    action: SnackBarActionConfig(
      label: S.of(context).errorReportLabel,
      onPressed: () => GithubIssueService.createIssueFromError(
        context,
        stackTrace: stackTrace,
      ),
    ),
  );
  log(
    "An error has occurred.",
    error: error,
    stackTrace: stackTrace,
    time: DateTime.now(),
  );
}

void showErrorMessage(
  BuildContext context,
  PaperlessServerException error, [
  StackTrace? stackTrace,
]) {
  showSnackBar(
    context,
    translateError(context, error.code),
    details: error.details,
  );
  log(
    "An error has occurred.",
    error: error,
    stackTrace: stackTrace,
    time: DateTime.now(),
  );
}

bool isNotNull(dynamic value) {
  return value != null;
}

String formatDate(DateTime date) {
  return dateFormat.format(date);
}

String? formatDateNullable(DateTime? date) {
  if (date == null) return null;
  return dateFormat.format(date);
}

String extractFilenameFromPath(String path) {
  return path.split(RegExp('[./]')).reversed.skip(1).first;
}

// Taken from https://github.com/flutter/flutter/issues/26127#issuecomment-782083060
Future<void> loadImage(ImageProvider provider) {
  final config = ImageConfiguration(
    bundle: rootBundle,
    devicePixelRatio: window.devicePixelRatio,
    platform: defaultTargetPlatform,
  );
  final Completer<void> completer = Completer();
  final ImageStream stream = provider.resolve(config);

  late final ImageStreamListener listener;

  listener = ImageStreamListener((ImageInfo image, bool sync) {
    debugPrint("Image ${image.debugLabel} finished loading");
    completer.complete();
    stream.removeListener(listener);
  }, onError: (dynamic exception, StackTrace? stackTrace) {
    completer.complete();
    stream.removeListener(listener);
    FlutterError.reportError(FlutterErrorDetails(
      context: ErrorDescription('image failed to load'),
      library: 'image resource service',
      exception: exception,
      stack: stackTrace,
      silent: true,
    ));
  });

  stream.addListener(listener);
  return completer.future;
}
