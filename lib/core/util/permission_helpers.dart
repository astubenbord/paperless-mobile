import 'dart:developer';

import 'package:permission_handler/permission_handler.dart';

Future<bool> askForPermission(Permission permission) async {
  final status = await permission.request();
  log("Permission requested, new status is $status");
  // If user has permanently declined permission, open settings.
  if (status == PermissionStatus.permanentlyDenied) {
    await openAppSettings();
  }

  return status == PermissionStatus.granted;
}
