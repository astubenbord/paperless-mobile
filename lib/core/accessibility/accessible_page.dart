import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce/hive.dart';
import 'package:paperless_mobile/core/database/hive/hive_config.dart';
import 'package:paperless_mobile/core/database/hive/hive_extensions.dart';

Page<T> accessiblePlatformPage<T>({
  required Widget child,
  String? name,
  Object? arguments,
  String? restorationId,
  LocalKey? key,
  bool allowSnapshotting = true,
  bool fullscreenDialog = false,
  bool maintainState = true,
  String? title,
}) {
  final shouldDisableAnimations = WidgetsBinding.instance.disableAnimations ||
      Hive.globalSettingsBox.getValue()!.disableAnimations;
  if (shouldDisableAnimations) {
    return NoTransitionPage(
      key: key,
      name: name,
      arguments: arguments,
      restorationId: restorationId,
      child: child,
    );
  }
  if (Platform.isAndroid) {
    return MaterialPage(
      child: child,
      name: name,
      restorationId: restorationId,
      arguments: arguments,
      allowSnapshotting: allowSnapshotting,
      fullscreenDialog: fullscreenDialog,
      key: key,
      maintainState: maintainState,
    );
  } else if (Platform.isIOS) {
    return CupertinoPage(
      child: child,
      allowSnapshotting: allowSnapshotting,
      arguments: arguments,
      fullscreenDialog: fullscreenDialog,
      key: key,
      maintainState: maintainState,
      name: name,
      restorationId: restorationId,
      title: title,
    );
  }
  throw UnsupportedError("The current platform is not supported.");
}
