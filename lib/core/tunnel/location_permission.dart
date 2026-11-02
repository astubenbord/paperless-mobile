import 'package:permission_handler/permission_handler.dart';

abstract class LocationPermission {
  Future<PermissionStatus> status();
  Future<PermissionStatus> request();
  Future<bool> openSettings();
  bool isPermanentlyDenied(PermissionStatus status);
}

class LocationPermissionHandler implements LocationPermission {
  @override
  Future<PermissionStatus> status() => Permission.locationWhenInUse.status;
  @override
  Future<PermissionStatus> request() => Permission.locationWhenInUse.request();
  @override
  Future<bool> openSettings() => openAppSettings();
  @override
  bool isPermanentlyDenied(PermissionStatus status) =>
      status.isPermanentlyDenied;
}
